---
title: "Connecting to the EIDF Cerebras Cluster"
teaching: 20
exercises: 15
---

::::::::::::::::::::::::::::::::::::::: objectives

- Understand how to connect to the EIDF Cerebras Cluster.

- Set up the environment and tools for the tutorial.

::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::: questions

- How can I access the EIDF Cerebras Cluster interactively?

- How does Cerebras set up and interact with LLMs/ML models? 

::::::::::::::::::::::::::::::::::::::::::::::::::

## Connecting using SSH

The EIDF Cerebras Cluster is accessed through the EIDF Gateway. 
To access the Cerebras Cluster, you need to proxy through the 
EIDF Gateway.

The EIDF Gateway login address is

``` bash
eidf-gateway.epcc.ed.ac.uk
```

and to connect to the Cerebras cluster, you will need to run 
the following command:

``` bash
ssh -J <username>@eidf-gateway.epcc.ed.ac.uk cerebras
```

Access to the EIDF Cerebras Cluster is via SSH using **both** 
a time-based code (TOTP) and a passphrase-protected SSH key 
pair. As an additional security measure, newly created 
accounts must also use a one time password retrieved from 
the SAFE web adminsitration service for the first ever login.

You can find more information about logging in to the 
EIDF Cerebras Cluster in the 
[EIDF Documentations](https://docs.eidf.ac.uk/services/cerebras/connect/)


## Set up Cerebras Model Zoo (if you haven't done so yet)

Throughout the tutorial we will use tools from the Model Zoo.
From the Cerebras cluster do following one-time steps:

```bash
git clone -b Release_2.10.0 https://github.com/Cerebras/modelzoo.git ./modelzoo
python3.11 -m venv modelzoo_venv
source modelzoo_venv/bin/activate
pip install --upgrade pip
pip install --editable ./modelzoo
```
When re-connecting to load the environment again:
```bash
source modelzoo_venv/bin/activate
```

:::::::::::::::::::::::::::::::::::::::: keypoints

- The EIDF Cerebras Cluster is accessed through the EIDF Gateway
- The EIDF Gateway login address is `eidf-gateway.epcc.ed.ac.uk`
- The Cerebras Model Zoo provides tools to interact with ML models. 
- When re-connecting to the cluster load the environment with:
  ```bash
  source modelzoo_venv/bin/activate
  ```

::::::::::::::::::::::::::::::::::::::::::::::::::
