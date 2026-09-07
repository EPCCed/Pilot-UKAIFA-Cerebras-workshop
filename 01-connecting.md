---
title: "Connecting to the EIDF Cerebras Cluster"
teaching: 20
exercises: 15
---

::::::::::::::::::::::::::::::::::::::: objectives

- Understand how to connect to the EIDF Cerebras Cluster.

::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::: questions

- How can I access the EIDF Cerebras Cluster interactively?

::::::::::::::::::::::::::::::::::::::::::::::::::

The first few parts of this are to give you an idea of 
what's possible with this template. Then it gets into 
the course that you'd developed.

:::::::::::::::::::::::::::::::::::::::  challenge

## An exercise with a title

This lets you present exercises for course 
attendees to do.

:::::::::::::::  solution

## Solution

And this is where the solution would be.

:::::::::::::::::::::::::

You can also potentially add text after the exercise
(and other questions and solutions too).

::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::  callout
                                                                ## Callouts (with their own titles)

You can also have callouts to make some info really obvious.

When you're writing these, you'll notice that you need to 
include the lines of colons ":" at the start and end of a 
section.
                                                                ::::::::::::::::::::::::::::::::::::::::::::::::::

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

:::::::::::::::::::::::::::::::::::::::: keypoints

- The EIDF Cerebras Cluster is accessed through the EIDF Gateway
- The EIDF Gateway login address is `eidf-gateway.epcc.ed.ac.uk`


::::::::::::::::::::::::::::::::::::::::::::::::::
