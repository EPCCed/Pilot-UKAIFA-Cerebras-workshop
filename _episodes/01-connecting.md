---
title: "Connecting to the EIDF Cerebras Cluster"
teaching: 20
exercises: 15
questions:
- "How can I access the EIDF Cerebras Cluster interactively?"
objectives:
- "Understand how to connect to the EIDF Cerebras Cluster."
keypoints:
- "The EIDF Cerebras Cluster is accessed through the EIDF Gateway"
- "The EIDF Gateway login address is `eidf-gateway.epcc.ed.ac.uk`."
---

## Connecting using SSH

The EIDF Cerebras Cluster is accessed through the EIDF Gateway. 
To access the Cerebras Cluster, you need to proxy through the 
EIDF Gateway.

The EIDF Gateway login address is

```
eidf-gateway.epcc.ed.ac.uk
```
{: .language-bash}

and to connect to the Cerebras cluster, you will need to run 
the following command:

```
ssh -J <username>@eidf-gateway.epcc.ed.ac.uk cerebras
```
{: .language-bash}

Access to the EIDF Cerebras Cluster is via SSH using **both** 
a time-based code (TOTP) and a passphrase-protected SSH key 
pair. As an additional security measure, newly created 
accounts must also use a one time password retrieved from 
the SAFE web adminsitration service for the first ever login.

You can find more information about logging in to the 
EIDF Cerebras Cluster in the 
[EIDF Documentations](https://docs.eidf.ac.uk/services/cerebras/connect/)

{% include links.md %}

