---
title: "Downloading the model"
teaching: 30
exercises: 15
questions:
- "How do I download my pre-trained model to the EIDF Cerebras Cluster"
objectives:
- ""
keypoints:
- ""
---

**NOTE**: For the running of the workshop, it might be fun to 
have some of the attendees re-train Llama2 and some retrain 
Llama3 -- that could help promote the message around benchmark 
ingestion.

## Downloading the Model

Here we get the pre-trained 'out of the box' model, in this 
case we will use Llama2.
At this stage you'll need to have your HuggingFace account 
set up and a token for authentication.
If you haven't done so before you can find information on 
HF login [here](https://huggingface.co/docs/huggingface_hub/main/en/quick-start#login-command). 

Llama3, which is also supported in the Cerebras Modelzoo, 
was released after the dataset and likely was pretrained 
on the test data we want to evaluate, so Llama2 offers a 
fairer baseline. 

Let's create `download_model.py` we can run to download the 
model from HuggingFace in the Cerebras session, replacing 
`<your-home-dir>`: 

```python
# download_model.py file
#   You may need to 'pip install huggingface_hub' before 
#   running this bit if not installed yet
#   from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="meta-llama/Llama-2-7b-hf",
    local_dir="<your-home-dir>/finetuning_llama2/from_hf",
    local_dir_use_symlinks=False,
    ignore_patterns=["*.pth", "*.gguf"],  # Skip non-HF formats
)
print("Download finished!")
```

To find more information on the models compatible with the 
modelzoo tools you can check the 
[cerebras documentation pages](https://training-docs.cerebras.ai/rel-2.10.0/model-zoo/models/nlp/llama#llama-2)
and look through the available configurations under 
`modelzoo/src/cerebras/modelzoo/models/`.

Run it:

```bash
mkdir -p ~/finetuning_llama2/from_hf
python download_model.py

# Verify essential files

ls -lh ~/finetuning_llama2/from_hf/

# after you should see:
#  *  config.json
#  *  pytorch_model-*.bin
#  * tokeniser files
#  * etc.
```

The file `~/finetuning_llama2/from_hf/config.json` will 
have important information and paramters of model that we 
will need later on (`vocab_size`,layer structure info, etc.).

{% include links.md %}

