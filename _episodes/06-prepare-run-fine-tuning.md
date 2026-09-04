---
title: "Prepare and run the model fine-tuning"
teaching: 15
exercises: 0
questions:
- ""
objectives:
- ""
keypoints:
- ""
---

## Preparing the model fine-tuning

This is the main configuration for the fine tuning.
It defines the model architecture, the optimiser to be used,
data loaders, etc.

In general one shouldn't expect to write these configurations 
from scratch, there's a few options that can be used as 
templates, for example `modelzoo/blob/main/src/cerebras/modelzoo/models/nlp/llama/configs/params_llama2_7b.yaml`
can be a starting point for our Llama2 setup.

Create `finetuning_llama2/model_config_gsm8k.yaml`, and 
fill it in section by section, replacing `<your-home-dir>`
where necessary, and being careful to __maintain the same indentation throughout__.

First there's a few general settings like the model output 
directory, backend type:

```yaml
# model_config_gsm8k.yaml file

trainer:
  init:
    backend:
      backend_type: CSX
      cluster_config:
        num_csx: 1

    model_dir: finetuning_llama2/model
    seed: 42
```

Next some details about the model, lots of these are listed 
in the model's `config.json` and the modelzoo Llama2 
parameter configuration:

```yaml
# continued model_config_gsm8k.yaml file
    model:
      name: "llama"
      vocab_size: 32000
      hidden_size: 4096
      num_hidden_layers: 32
      num_heads: 32
      max_position_embeddings: 4096
      attention_module: "multiquery_attention"
      attention_dropout_rate: 0.0
      extra_attention_params:
        num_kv_groups: 32
      attention_type: "scaled_dot_product"
      position_embedding_type: "rotary"
      pos_scaling_factor: 1.0
      rotary_dim: 128
      rope_theta: 10000.0
      filter_size: 11008
      nonlinearity: "swiglu"
      use_ffn_bias: false
      use_projection_bias_in_attention: false
      use_ffn_bias_in_attention: false
      norm_type: "rmsnorm"
      layer_norm_epsilon: 1.0e-5
      share_embedding_weights: false
      embedding_layer_norm: false
      use_bias_in_output: false
      # Regularization off for fine-tuning
      embedding_dropout_rate: 0.0
      dropout_rate: 0.0
      loss_scaling: "num_tokens"
      loss_weight: 1.0
```

Next we set up the optimiser, logging, checkpoints and similar.

```yaml
# continued model_config_gsm8k.yaml file

    optimizer:
      AdamW:
        weight_decay: 0.01

    schedulers:
      - LinearLR:
          initial_learning_rate: 1.0e-5
          end_learning_rate: 0.0
          total_iters: 1680 # Must match max_steps

    loop:
      max_steps: 1680
      eval_steps: 300

    precision:
      enabled: true
      fp16_type: cbfloat16
      loss_scaling_factor: dynamic

    callbacks:
    - ComputeNorm: {}
    checkpoint:
      steps: 840
    logging:
      log_steps: 10
```

The estimate of total iterations is based on the number of 
examples in the training dataset.
There are around 6725 training examples, so at `batch_size: 8` 
(set below), one epoch is just over 840 steps. For 2 epochs, 
`max_steps = 1680`.

Finally we set up the data loading and the training 
parameters, replacing `<your-home-dir>`:

```yaml
# continued model_config_gsm8k.yaml file

  fit:
    train_dataloader:
      data_processor: "GptHDF5MapDataProcessor"
      data_dir: "<your-home-dir>/finetuning_llama2/train_data"
      batch_size: 8
      shuffle: true
      num_workers: 8
      persistent_workers: true
      prefetch_factor: 10
      shuffle_seed: 42

    val_dataloader: &val_dataloader
      data_processor: "GptHDF5MapDataProcessor"
      data_dir: "<your-home-dir>/finetuning_llama2/valid_data"
      batch_size: 8
      shuffle: false
      num_workers: 8

    ckpt_path: "finetuning_llama2/from_hf/pytorch_model_to_cs-2.9.mdl"

  validate:
    val_dataloader: *val_dataloader

  validate_all:
    val_dataloaders: *val_dataloader

```

With this all set up we can finally run the fine tuning!

## Running the model fine tunning

To run the fine tuning, save weights, etc. we run:

```bash
cd $HOME
cszoo fit finetuning_llama2/model_config_gsm8k.yaml \
  --mount_dirs ~/ \
  --python_paths ~/finetuning_llama2
```

We can follow the log and check that the loss decreases and
a final checkpoint is saved to `finetuning_llama2/model/`:

```
...
2026-07-27 18:25:29,492 INFO:   | Train Device=CSX, Step=1590, Loss=0.15949, Rate=22.37 samples/sec, GlobalRate=8.44 samples/sec, LoopTimeRemaining=0:10:52, TimeRemaining>0:10:52
2026-07-27 18:25:33,294 INFO:   | Train Device=CSX, Step=1600, Loss=0.14608, Rate=20.76 samples/sec, GlobalRate=8.48 samples/sec, LoopTimeRemaining=0:10:52, TimeRemaining>0:10:52
2026-07-27 18:25:37,180 INFO:   | Train Device=CSX, Step=1610, Loss=0.26339, Rate=20.88 samples/sec, GlobalRate=8.51 samples/sec, LoopTimeRemaining=0:10:52, TimeRemaining>0:10:52
2026-07-27 18:25:41,002 INFO:   | Train Device=CSX, Step=1620, Loss=0.19274, Rate=21.29 samples/sec, GlobalRate=8.54 samples/sec, LoopTimeRemaining=0:10:52, TimeRemaining>0:10:52
2026-07-27 18:25:44,854 INFO:   | Train Device=CSX, Step=1630, Loss=0.29205, Rate=20.67 samples/sec, GlobalRate=8.57 samples/sec, LoopTimeRemaining=0:10:52, TimeRemaining>0:10:52
2026-07-27 18:25:49,407 INFO:   | Train Device=CSX, Step=1640, Loss=0.23772, Rate=17.31 samples/sec, GlobalRate=8.60 samples/sec, LoopTimeRemaining=0:10:52, TimeRemaining>0:10:52
2026-07-27 18:25:54,240 INFO:   | Train Device=CSX, Step=1650, Loss=0.17637, Rate=16.04 samples/sec, GlobalRate=8.62 samples/sec, LoopTimeRemaining=0:10:52, TimeRemaining>0:10:52
2026-07-27 18:25:59,185 INFO:   | Train Device=CSX, Step=1660, Loss=0.16029, Rate=18.00 samples/sec, GlobalRate=8.65 samples/sec, LoopTimeRemaining=0:10:52, TimeRemaining>0:10:52
2026-07-27 18:26:04,654 INFO:   | Train Device=CSX, Step=1670, Loss=0.15825, Rate=14.73 samples/sec, GlobalRate=8.67 samples/sec, LoopTimeRemaining=0:10:52, TimeRemaining>0:10:52
2026-07-27 18:26:09,905 INFO:   | Train Device=CSX, Step=1680, Loss=0.16981, Rate=15.09 samples/sec, GlobalRate=8.69 samples/sec, LoopTimeRemaining=0:10:52, TimeRemaining>0:10:52
2026-07-27 18:26:09,913 INFO:   Saving checkpoint at step 1680
Saving checkpoint: 100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 1864/1864 [13:22<00:00,  2.32 tensors/s]
...
# also the evaluation steps
...
2026-07-27 18:41:53,674 INFO:   | Eval Device=CSX, GlobalStep=1680, Batch=240, Loss=0.52876, Rate=59.43 samples/sec, GlobalRate=58.71 samples/sec, LoopTimeRemaining=0:00:08, TimeRemaining=0:00:08
2026-07-27 18:41:55,040 INFO:   | Eval Device=CSX, GlobalStep=1680, Batch=250, Loss=0.35506, Rate=58.74 samples/sec, GlobalRate=58.70 samples/sec, LoopTimeRemaining=0:00:07, TimeRemaining=0:00:07
2026-07-27 18:41:56,405 INFO:   | Eval Device=CSX, GlobalStep=1680, Batch=260, Loss=0.49279, Rate=57.94 samples/sec, GlobalRate=58.70 samples/sec, LoopTimeRemaining=0:00:05, TimeRemaining=0:00:05
2026-07-27 18:41:57,763 INFO:   | Eval Device=CSX, GlobalStep=1680, Batch=270, Loss=0.41518, Rate=59.62 samples/sec, GlobalRate=58.71 samples/sec, LoopTimeRemaining=0:00:04, TimeRemaining=0:00:04
2026-07-27 18:41:59,129 INFO:   | Eval Device=CSX, GlobalStep=1680, Batch=280, Loss=0.42419, Rate=57.42 samples/sec, GlobalRate=58.70 samples/sec, LoopTimeRemaining=0:00:03, TimeRemaining=0:00:03
2026-07-27 18:42:00,491 INFO:   | Eval Device=CSX, GlobalStep=1680, Batch=290, Loss=0.47431, Rate=57.32 samples/sec, GlobalRate=58.70 samples/sec, LoopTimeRemaining=0:00:01, TimeRemaining=0:00:01
2026-07-27 18:42:01,848 INFO:   | Eval Device=CSX, GlobalStep=1680, Batch=300, Loss=0.38198, Rate=58.42 samples/sec, GlobalRate=58.71 samples/sec, LoopTimeRemaining=0:00:00, TimeRemaining=0:00:00
2026-07-27 18:42:04,110 INFO:   Avg Eval Loss: 0.3819842774172624
2026-07-27 18:42:04,150 INFO:   Evaluation metrics:
2026-07-27 18:42:04,153 INFO:     - eval/lm_perplexity = 1.4673088788986206
2026-07-27 18:42:04,155 INFO:     - eval/accuracy = 0.8949702978134155
2026-07-27 18:42:04,157 INFO:   Evaluation completed successfully!
2026-07-27 18:42:04,178 INFO:   Processed 13440 training sample(s) in 2789.260229544 seconds.
```

{% include links.md %}

