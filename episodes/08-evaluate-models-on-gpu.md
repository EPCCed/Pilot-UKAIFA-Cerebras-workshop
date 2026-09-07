---
title: "Evaluating model performance on GPUs"
teaching: 10
exercises: 50
questions:
- ""
objectives:
- ""
keypoints:
- ""
---

## Evaluating base and fine-tuned models on GPU

While cerebras does provide some tools for model evaluation, 
we have already have a good, more flexible setup to evaluate 
in GPU which we can use from [the previous tutorial](../../epcc/eidf/getting-started-with-the-gpu-service-and-llms/blob/main/train_gsm8k.md).

### Accessing the fine-tuned and base models from the GPU service

The cerebras and GPU service machines both have access to 
the shared `cephfs` storage area.
We can copy those checkpoints to the right directory:

```bash
# first make a few directories to copy our checkpoints into

mkdir -p /home/eidf114/eidf114/shared/<your-user-name-or-similar>/
mkdir -p /home/eidf114/eidf114/shared/<your-user-name-or-similar>/checkpoint_0_from_hf

# first the fine-tuned version

cp -r finetuning_llama2/to_hf/checkpoint_1680_to_hf /home/eidf114/eidf114/shared/<your-user-name-or-similar>/finetune_llama2/

# next the relevant files from the original checkpoint

cp finetuning_llama2/from_hf/config.json /home/eidf114/eidf114/shared/<your-user-name-or-similar>/finetune_llama2/checkpoint_0_from_hf/
cp finetuning_llama2/from_hf/pytorch_model-00001-of-00002.bin /home/eidf114/eidf114/shared/<your-user-name-or-similar>/finetune_llama2/checkpoint_0_from_hf/
cp finetuning_llama2/from_hf/pytorch_model-00002-of-00002.bin /home/eidf114/eidf114/shared/<your-user-name-or-similar>/finetune_llama2/checkpoint_0_from_hf/
cp finetuning_llama2/from_hf/pytorch_model.bin.index.json /home/eidf114/eidf114/shared/<your-user-name-or-similar>/finetune_llama2/checkpoint_0_from_hf/
```

With these copied over we should now be able to access them from a pytorch kubernetes pod.

To access it we need to configure the job with some extras 
added to the configuration in
[this tutorial](https://s3.eidf.ac.uk/eidf003:datasets/index.html#/?id=change-jupyterlab-working-directory),
in particular the `securityContext` and `volumeMounts` sections.
More information on this available in [this EIDF documentation page](https://docs.eidf.ac.uk/safe-haven-services/tre-gpu-service/training/L4_requesting_persistent_volumes/#how-to-find-your-uid-and-gid-on-the-shs-desktop-vm).

```yaml
# pytorch-job-shared-pvc.yaml file
apiVersion: batch/v1
kind: Job
metadata:
  generateName: my-gsm8k-ftune-
  labels:
    kueue.x-k8s.io/queue-name: eidf114ns-user-queue
spec:
  completions: 1
  backoffLimit: 1
  ttlSecondsAfterFinished: 1800
  template:
    metadata:
      name: pytorch-pod
    spec:
      securityContext:
        runAsUser: <your-uid>
        runAsGroup: <your-gid>
        # 100,1000 here are to pass on permissions to the 'jovyan' user in the notebook
        # also, I'm not sure if including comments here will break the config so remove it if there's issues
        supplementalGroups:
          - <your-gid-again>
          - 100
          - 1000
      containers:
      - name: pytorch
        image: quay.io/jupyter/pytorch-notebook:cuda12-latest
        resources:
          requests:
            cpu: 2
            memory: '4Gi'
          limits:
            cpu: 4
            memory: '8Gi'
            nvidia.com/gpu: 1
        env:
          - name: HOME
            value: /home/jovyan
          - name: USER
            value: jovyan
          - name: HF_TOKEN
            valueFrom:
              secretKeyRef:
                name: hf-secret
                key: HF_TOKEN
          - name: NOTEBOOK_ARGS
            value: "--ip 0.0.0.0 --notebook-dir=/mnt/data --preferred_dir=/mnt/data"
        volumeMounts:
          - mountPath: /etc/passwd
            name: passwd-config
            subPath: passwd
          - mountPath: /mnt/data
            name: volume
          - mountPath: /mnt/cephfs-shared
            name: cephfs
      restartPolicy: Never
      volumes:
      - name: passwd-config
        configMap:
          name: passwd-config
      - name: volume
        persistentVolumeClaim:
          claimName: my-pvc-llmtune-rscwd # this is a pvc I had set up before
      - name: cephfs
        persistentVolumeClaim:
          claimName: cephfs-shared
      nodeSelector:
        nvidia.com/gpu.product: NVIDIA-A100-SXM4-40GB-MIG-3g.20gb
```

### Side-quest: passing HF login token to the kubernetes pod

Early on in this tutorial we had to get access to Llama2 in 
hugging face, and we had to generate a token for this.
In the evaluation step we need to access it again, meaning 
we'll need to authenticate in the gpu service machines as 
well and in any VM we run from.
_* You may be able to authenticate via CLI directly in the 
pod, but this way we avoid having to generate new tokens 
every time._

So, this is where the `HF_TOKEN` and `secretKeyRef` above 
come in, it is a one off setup and not too complicated.
First we create the password configMap as a new yaml file 
`passwd-configmap.yaml`, replacing your `uid` and `gid`s:

```yaml
# passwd-configmap.yaml file
apiVersion: v1
kind: ConfigMap
metadata:
  name: passwd-config
  namespace: eidf114nskk
data:
  passwd: |
    root:x:0:0:root:/root:/bin/bash
    jovyan:x:<your-uid>:<your-gid>::/home/jovyan:/bin/bash
```

Next we create a kubernetes 'secret' (you may need to 
create generate a new HF token through your profile 
settings) and apply the map:

```bash
# one off commands

kubectl -n eidf114ns apply -f passwd-configmap.yaml
kubectl create secret generic hf-secret --from-literal=HF_TOKEN=<hf_your_token_here>
```

Finally add the `HF_TOKEN` section in `env` in the job 
configuration, and crate the pod.

### Evaluate the models

With the shared `cephfs` disk and the HF authentication set 
up, we can run the evaluation, and see what the fine tuning 
has done! 
If all went well you should see your disk mounted 
`/mnt/cephfs-shared` as configured above.

We will again need to install a few packages:

```bash
pip install transformers datasets accelerate nvitop 
```

Below are some familiar steps and functions to import the 
model, tokenise the data, evaluate `gsm8k`, etc.

```python
import os
from datasets import load_dataset
from transformers import set_seed, AutoTokenizer, AutoModelForCausalLM
from sympy import sympify, simplify, SympifyError
import torch
from torch.utils.data import DataLoader
import torch.nn.functional as F

import gc
import re
import numpy as np

import json
from datetime import datetime

# ----- constants -----
MAX_INPUT      = 256
MAX_NEW_TOKENS = 256

MODEL_ID   = "meta-llama/Llama-2-7b-hf" # same as download_model.py
# --- change these two below when evaluating the fine-tuned version
OUTPUT_DIR = "./baseline_llama2_7b/" 
CHECKPOINT_PATH = "/mnt/cephfs-shared/<your-user-name-or-similar>/checkpoint_0_from_hf/"
# ---
EVAL_BS    = 8
SEED       = 42

# llama 2 template

PROMPT_TEMPLATE = (
    "Solve the following math problem step by step. "
    "At the end of your solution, write 'The answer is <number>'.\n\n"
    "Problem: {question}\n"
    "Solution:"
)

# ----- reproducibility & matmul (matrix multiplication) flags -----

set_seed(SEED)
torch.backends.cuda.matmul.allow_tf32 = True
torch.backends.cudnn.allow_tf32 = True

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")
if device.type == "cuda":
    print(f"  GPU: {torch.cuda.get_device_name(0)}")
    print(f"  VRAM available: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")

# Note: training data isn't necessary this time around - we 
# are just using the test set.

raw_test  = load_dataset("openai/gsm8k", "main", split="test")

test_set   = raw_test
```

If we run the code above we should see the available device 
and VRAM - the 20 gb slice we requested should run fine 
with the parameters above.
Next we set up the tokeniser:

```python
# ----- tokeniser -----
## Remember the 'z' spelling 
## 
## Note: you can use the checkpoint directory instead of 
## MODEL_ID (if available)

tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)

# llama2 has no dedicated pad token - map it to eos (end of 
# sequence) 

tokenizer.pad_token    = tokenizer.eos_token
tokenizer.padding_side = "left"


def build_prompt(question: str) -> str:
    """Plain-text completion prompt suitable for the LLaMA-2 base model."""
    return PROMPT_TEMPLATE.format(question=question)


def format_gsm8k(batch):
    return {
        "input":  [build_prompt(q) for q in batch["question"]],
        "output": batch["answer"],
    }

test_set   = test_set.map(format_gsm8k,   batched=True)


print("\nSample test_set[1111]:")
print(test_set[1111])


def tokenize(batch):
    """Tokenise input prompts only - labels are decoded from generated output and no need for training set labels."""
    return tokenizer(
        batch["input"],
        max_length=MAX_INPUT,
        truncation=True,
        padding=False,   # collate_fn handles per-batch padding
    )

tokenized_test_set = test_set_filtered.map(
    tokenize,
    batched=True,
    remove_columns=test_set_filtered.column_names,
)

print("Tokenized test set columns:", tokenized_test_set.column_names)
print("Size:", len(tokenized_test_set))
```

Next the functions to test the math answers, and fallback 
options:

```python
# --- answer utilities -----
def math_equal(a_str, b_str):
    if a_str == b_str:
        return True
    try:
        return abs(float(a_str) - float(b_str)) < 1e-6
    except ValueError:
        pass
    try:
        return simplify(sympify(a_str) - sympify(b_str)) == 0
    except (SympifyError, TypeError, ValueError):
        return False


def extract_answer(text):
    """Return value after #### (GSM8K label format) or after 'The answer is', fallback is to take last number that was generated."""
    # GSM8K ground-truth labels
    match = re.search(r"####\s*(-?[\d,]+(?:\.\d+)?)", text)
    if match:
        return match.group(1).replace(",", "").strip()
    # LLaMA-2 generation - as specified in PROMPT_TEMPLATE
    match = re.search(r"[Tt]he answer is[:\s]+(-?[\d,]+(?:\.\d+)?)", text)
    if match:
        return match.group(1).replace(",", "").strip()
    # Fallback: last number in text
    numbers = re.findall(r"-?[\d,]+(?:\.\d+)?", text)
    return numbers[-1].replace(",", "").strip() if numbers else ""


def extract_numbers(text):
    return {m.replace(",", "") for m in re.findall(r"-?[\d,]+(?:\.\d+)?", text)}
```

Finally we set up the model parameters and define the 
evaluation functions:

```python
# ----- model -----
my_model = AutoModelForCausalLM.from_pretrained(
    CHECKPOINT_PATH,
    torch_dtype=torch.bfloat16,
    device_map="auto",
)
my_model.config.use_cache = True
my_model = torch.compile(my_model)
print("Model compiled with torch.compile")
if device.type == "cuda":
    print(f"VRAM used after load: {torch.cuda.memory_allocated() / 1e9:.2f} GB")


def generate_answer(model, question=None, input_ids=None, attention_mask=None):
    """Single-sample inference wrapper (no batching, so no padding issue). Use for interactive testing only."""
    model.eval()
    model_device = next(model.parameters()).device

    # handle either id numbers in gsm8k  or plain text questions
    if input_ids is not None:
        input_ids_t      = torch.as_tensor(input_ids).unsqueeze(0).to(model_device)
        attention_mask_t = torch.as_tensor(attention_mask).unsqueeze(0).to(model_device)
        prompt_len       = input_ids_t.shape[1]
    elif question is not None:
        prompt = build_prompt(question)
        encoded = tokenizer(
            prompt, return_tensors="pt", truncation=True,
        ).to(model_device)
        input_ids_t      = encoded["input_ids"]
        attention_mask_t = encoded["attention_mask"]
        prompt_len       = input_ids_t.shape[1]
    else:
        raise ValueError("Either question or input_ids must be provided")

    with torch.no_grad():
        outputs = model.generate(
            input_ids=input_ids_t,
            attention_mask=attention_mask_t,
            max_new_tokens=MAX_NEW_TOKENS,
            num_beams=1,
            do_sample=False,
            pad_token_id=tokenizer.eos_token_id,
        )
    return tokenizer.decode(outputs[0][prompt_len:], skip_special_tokens=True)


# ----- evaluation tools -----

def collate_fn(batch):
    """Left-pad input_ids and attention_mask for batched causal generation."""
    input_ids      = [torch.as_tensor(x["input_ids"])      for x in batch]
    attention_mask = [torch.as_tensor(x["attention_mask"]) for x in batch]

    max_len = max(x.size(0) for x in input_ids)
    pad_id  = tokenizer.pad_token_id  # eos_token_id, set above

    input_ids_padded = torch.stack([
        F.pad(x, (max_len - x.size(0), 0), value=pad_id) for x in input_ids
    ])
    attention_mask_padded = torch.stack([
        F.pad(m, (max_len - m.size(0), 0), value=0) for m in attention_mask
    ])
    return input_ids_padded, attention_mask_padded



def evaluate_model(model, dataset, raw_dataset, batch_size=EVAL_BS,
                   output_dir=OUTPUT_DIR, run_tag=None):
    model.eval()
    model.config.use_cache = True
    model_device = next(model.parameters()).device

    os.makedirs(output_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    tag       = f"_{run_tag}" if run_tag else ""
    log_path  = os.path.join(output_dir, f"eval_{timestamp}{tag}.txt")

    def log(msg, also_print=True):
        if also_print:
            print(msg)
        with open(log_path, "a") as f:
            f.write(msg + "\n")

    log(f"{'='*60}")
    log(f"Evaluation run  : {timestamp}{tag}")
    log(f"Base model      : {MODEL_ID}")
    log(f"Checkpoint      : {CHECKPOINT_PATH}")
    log(f"Batch size      : {batch_size}")
    log(f"Max new tokens  : {MAX_NEW_TOKENS}")
    log(f"Test samples    : {len(dataset)}")
    log(f"{'='*60}")

    loader = DataLoader(
        dataset.with_format("torch"),
        batch_size=batch_size,
        shuffle=False,
        num_workers=4,
        pin_memory=True,
        collate_fn=collate_fn,
    )

    correct         = 0
    total           = 0
    correct_indices = []
    labels_list     = raw_dataset["output"]
    t_start         = datetime.now()

    # collate_fn returns  (input_ids, attention_mask)
    for batch_idx, (input_ids, attention_mask) in enumerate(loader):
        input_ids      = input_ids.to(model_device,      non_blocking=True)
        attention_mask = attention_mask.to(model_device, non_blocking=True)

        # After left-padding, generated tokens for every sample in the batch
        # start at the same offset: the padded input length.
        padded_input_len = input_ids.shape[1]

        with torch.no_grad():
            outputs = model.generate(
                input_ids=input_ids,
                attention_mask=attention_mask,
                max_new_tokens=MAX_NEW_TOKENS,
                num_beams=1,
                do_sample=False,
                pad_token_id=tokenizer.eos_token_id,
            )

        # Slice off the left-padded prompt prefix, identical 
        # offset for all samples
        preds = [
            tokenizer.decode(
                outputs[i][padded_input_len:],
                skip_special_tokens=True,
            )
            for i in range(outputs.shape[0])
        ]

        for j, (pred, label) in enumerate(
            zip(preds, labels_list[batch_idx * batch_size : batch_idx * batch_size + len(preds)])
        ):
            if math_equal(extract_answer(pred), extract_answer(label)):
                correct += 1
                correct_indices.append(batch_idx * batch_size + j)
            total += 1

        if batch_idx % 5 == 0:
            torch.cuda.empty_cache()
            elapsed = (datetime.now() - t_start).total_seconds()
            samples_per_sec = total / elapsed if elapsed > 0 else 0
            log(f"  [{total:>4}/{len(dataset)}]  "
                f"acc: {correct}/{total} = {correct/total:.3f}  "
                f"({samples_per_sec:.1f} samples/s)")

    elapsed_total   = (datetime.now() - t_start).total_seconds()
    samples_per_sec = len(dataset) / elapsed_total

    results = {
        "exact_match"    : correct / total,
        "correct"        : correct,
        "total"          : total,
        "correct_indices": correct_indices,
        "elapsed_s"      : round(elapsed_total, 2),
        "samples_per_sec": round(samples_per_sec, 2),
        "log_path"       : log_path,
    }

    summary = (
        f"\n{'='*60}\n"
        f"FINAL RESULTS\n"
        f"{'='*60}\n"
        f"  Exact match  : {results['exact_match']:.4f}\n"
        f"  Correct      : {results['correct']} / {results['total']}\n"
        f"  Elapsed      : {elapsed_total:.1f}s  ({samples_per_sec:.1f} samples/s)\n"
        f"  Log saved to : {log_path}\n"
        f"{'='*60}"
    )
    log(summary)

    json_path = os.path.join(output_dir, f"eval_{timestamp}{tag}.json")
    with open(json_path, "w") as f:
        json.dump(results, f, indent=2)
    log(f"  JSON saved to: {json_path}")

    return results
```

With all that set up we can use `generate_answer()` to get 
some qualitative examples:

```python
# ── qualitative examples ───────────────────────────────────────────────────────
EXAMPLE_INDICES = [100, 155] # we can choose any of the examples in the test set

# save any examples we run here to be logged after

example_records = []

for idx in EXAMPLE_INDICES:
    example   = test_set[idx]
    question  = example["question"]
    reference = example["answer"]
    ref_ans   = extract_answer(reference)
    tok       = tokenized_test_set[idx]

    base_output = generate_answer(
        my_model,
        input_ids=tok["input_ids"],
        attention_mask=tok["attention_mask"],
    )
    pred_ans = extract_answer(base_output)
    # ── store for later logging ──────────────────────────────────────────────
    example_records.append({
        "idx"       : idx,
        "question"  : question,
        "ref_ans"   : ref_ans,
        "pred_ans"  : pred_ans,
        "full_output": base_output,
        "correct"   : math_equal(pred_ans, ref_ans),
    })

    print(f"\n{'='*70}")
    print(f"EXAMPLE {idx}")
    print(f"{'='*70}")
    print(f"QUESTION:\n  {question}")
    print(f"\nREFERENCE ANSWER:  {ref_ans}")
    print(f"\nBASE OUTPUT:\n  {base_output}")
    print(f"  → extracted: {pred_ans!r}  "
          f"({'✓' if pred_ans == ref_ans else '✗'})")
```

Here we can see how the base model approaches the problems:

![](./res/gsm8k_base_180.png)
![](./res/gsm8k_base_599.png)

We can run the full evaluation to get the exact match score:

```python
# ----- full test set evaluation -----
print("Evaluating base model on test set …\n")
base_results = evaluate_model(my_model, tokenized_test_set, test_set)
print("\n── Results ─────────────────────────────────────")
print(f"  Exact match : {base_results['exact_match']:.4f}")
print(f"  Correct     : {base_results['correct']} / {base_results['total']}")

gc.collect()
torch.cuda.empty_cache()
```

This takes some time to run. 

As it progresses you should be able to see the partial 
accuracy, and it prints out a summary at the end which 
points to the location of the log and `.json` file with 
details of the evaluation.
The overall exact match fraction for the baseline model is 
not great - __between 2% and 4% correct__ in my testing, a 
lot of them correct just by chance.

We save the indices of correct answers in 
`base_results['correct_indices']` so we can check what the 
model did in more detail (same as we did above with the 
qualitative examples but replacing a correct answer index).

### Evaluating the fine-tuned model

Now that we know how Llama2 perfoms out of the box on this 
dataset, we can change `CHECKPOINT_DIR` and `OUTPUT_DIR` 
above, repeat the evaluation, and see what the fine tuning 
has achieved! 

The output is much more structured  and relevant now, even 
if some of its answers are not quite right. 
The model also now uses the syntax expected for step-by-step 
calculations `<</>>` and final answer `####` which it has 
learned from the dataset!

![](./res/gsm8k_finetuned_180.png)
![](./res/gsm8k_finetuned_599.png)


Below are some more examples from my testing:


Base Llama2:

![Base model](./res/gsm8k_base_prev_examples.png)


Fine-tuned Llama2:

![Fine-tuned model](./res/gsm8k_finetuned_prev_examples.png)



You've probably noticed it produces a lot of gibberish after 
it's finished answering, even if it's correct. 
The model accepts `stop_strings` which might be a way to 
limit output, but if it ends right at #### then extracting 
the answer won't work... maybe there's an option or 
workaround, but since doesn't affect the performance test, 
so it can be left as is. 
I wonder too if it's going into code-writing as gibberish 
because it probably has seen patterns of #s most prominently 
in code comments in its pretraining? :thinking_face:

{% include links.md %}
