---
carpentry: swc
venue: online
address: ~
country: UK
language: English
latlng: ~
humandate: 27 to 31 July 2026
humantime: ~
startdate: '2026-07-27'
enddate: '2026-07-31'
instructor:
- Santiago Paredes Saenz
helper: ''
email: 'info@ukaifa.org.uk'
collaborative_notes: ~
eventbrite: ~
site: sandpaper::sandpaper_site
---

<h2>Description</h2>

The aim of this workshop is to teach attendees how to train
a model on the EIDF Cerebras CS-3 cluster, extract the weights
of the trained model, and run them on a system with different
architecture (in this case, the EIDF GPU Cluster).

This workshop expands on the
[Cerebras Modelzoo quickstar tutorial](https://training-docs.cerebras.ai/rel-2.10.0/getting-started/fine-tune-your-first-model)
and specifically looks at fine-tune a model to perform a new
task.

<h2>Pre-requisites</h2>

Before getting started here are a few pre-requisites:

  * Access to the Cerebras cluster.
    * I also suggest following the Cerebras tutorial on
      the EIDF documentation.
  * A HuggingFace account and access to the Llama2 family
    of models.
    * Both are free, but access to the models needs to be
      requested and approved (it shouldn't take too long,
      I got approved roughly 30 min after requesting).
  * You may also want to follow the
    [EIDF tutorials](https://getting-started-with-the-gpu-service-and-llms-fbe560.pages.eidf.ac.uk/#/?id=beginner39s-guide-to-eidf-navigating-the-gpu-service-and-kubernetes),
    and specifically the
    [EIDF tutorial on fine tuning models](https://getting-started-with-the-gpu-service-and-llms-fbe560.pages.eidf.ac.uk/#/train?id=eidf-by-example).
    * A lot of the concepts and tool setup build on top of
      those (kubernetes pods, persistent volume claims,
      volume mounts, etc.)
    * The
      [train_gsm8k.md](https://gitlab.eidf.ac.uk/epcc/ukaifa/-/tree/main)
      specifically has information about the dataset we will
      use and how the evaluation is made.

<hr/>



<h2 id="general">General Information</h2>

<p id="requirements">
  <strong>Requirements:</strong> Participants must have a working laptop or 
  desktop computer with a Mac, Linux, or Windows operating system (not a 
  tablet, Chromebook, etc.) that they have administrative privileges on. They 
  should have access to a terminal (Mac and Linux users should have a terminal 
  installed by default; Windows users should get either 
  <a href="https://mobaxterm.mobatek.net/">MobaXterm</a> or 
  <a href="https://www.putty.org/">PuTTY</a>. They are also required to abide 
  by the <a href="https://www.archer2.ac.uk/training/code-of-conduct/">ARCHER2 Training Code of Conduct</a>.
</p>

::::::::::::::::::::::::::::::::::::::::::  prereq

## Prerequisites

You should have used remote HPC facilities before. In particular, you should be happy with connecting
using SSH, know what a batch scheduling system is and be familiar with using the Linux command line.
You should also be happy editing plain text files in a remote terminal (or, alternatively, editing them
on your local system and copying them to the remote HPC system using `scp`).


::::::::::::::::::::::::::::::::::::::::::::::::::

<hr/>

