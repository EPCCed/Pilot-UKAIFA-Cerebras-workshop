---
title: "Converting the fine-tuned model back to HuggingFace format"
teaching: 15
exercises: 0
questions:
- ""
objectives:
- ""
keypoints:
- ""
---

## Convert the fine-tuned CS model to HF format

When fine tuning is finished we can use the converter tools 
again in reverse to export back to HF and run a similar 
evaluation pipeline in the GPU service:

```bash
cszoo checkpoint convert --model llama \
  --src-fmt cs-2.9 --tgt-fmt hf \
  --config finetuning_llama2/model_config_gsm8k.yaml \
  --output-dir finetuning_llama2/to_hf \
  finetuning_llama2/model/checkpoint_1680.mdl
```

More information about converting CS to infer in GPU can be 
found in [this guide](./train_on_csx_then_infer_on_GPU.md)

{% include links.md %}

