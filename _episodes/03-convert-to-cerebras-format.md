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

## Convert HuggingFace checkpoint to Cerebras format

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

{% include links.md %}

