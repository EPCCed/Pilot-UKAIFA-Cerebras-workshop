---
title: "Converting "
teaching: 30
exercises: 10
questions:
- ""
objectives:
- ""
keypoints:
- ""
---

## Convert HF checkpoint to CS

Next we'll use the ModelZoo tools to convert the model 
weights we just got from hugging face to a format that 
Cerebras can use.
The Llama2 model we download is separated into 'shards' 
(separate files) with a `.json` file that the tool can use 
to piece it back together (something like 
`pytorch_model.bin.index.json`).

```bash
# below we indicate cs version 2.9 even though you've 
# probaly seen that this cs version is 2.10 this is because 
# the converter tools seeminlgy haven't  been updated, but 
# the 2.9 format works just fine

cszoo checkpoint convert \
  --model llama \
  --src-fmt hf \
  --tgt-fmt cs-2.9 \
  --config ~/finetuning_llama2/from_hf/config.json \
  --output-dir ~/finetuning_llama2/from_hf/ \
  ~/finetuning_llama2/from_hf/pytorch_model.bin.index.json
```

Check that the `*to_cs-2.9.mdl` model was produced successfully:

```bash
ls -lh ~/finetuning_llama2/from_hf/*.mdl
```

## Download and Format the Dataset

In this step we will download the maths dataset we will 
fine tune and use to test later.
We will also change the question and answer pairs to a 
format that Llama2 can process which expects a 
prompt-completion pair.
This is also the step where we split the training and 
testing data.


Create a `download_data.py` file:

```python
# download_data.py file

from datasets import load_dataset
import json
import os

# Note: We are using the "raw" version as it has not yet 
# been tokenised
base = "finetuning_llama2/gsm8k_raw"

for split in ["train", "valid"]:
    os.makedirs(f"{base}/{split}", exist_ok=True)

dataset = load_dataset("gsm8k", "main")

# Note: The test set is stored in dataset["test"]
tv = dataset["train"].train_test_split(test_size=0.1, seed=42)

# for fine tuning here we don't need the gsm8k test dataset. 
# We will leave it untouched and use only for evaluation at 
# the end. We can instead split the training set once more 
# into a train and validation 90/10 split for the fine 
# tuning process.
# 
# The train_test_split tool assigns 'test' as split name as 
# well, so we rename it to 'valid'

print(f"Train: {len(tv['train'])}, Valid: {len(tv['test'])}")

def save_jsonl(data, path):
    with open(path, "w") as f:
        for item in data:
            record = {
                "prompt": f"Question: {item['question']}\nAnswer:",
                "completion": f" {item['answer']}",
            }
            f.write(json.dumps(record) + "\n")

save_jsonl(tv["train"],       f"{base}/train/data.jsonl")
save_jsonl(tv["test"],        f"{base}/valid/data.jsonl")
print("Done!")
```

Run the download script!

```bash
python download_data.py

# You should see the `finetuning_llama2/gsm8k_raw/[train,valid]`
# populated now.
```

{% include links.md %}

