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
- William Lucas
helper: ''
email: 'w.lucas@epcc.ed.ac.uk'
collaborative_notes: ~
eventbrite: ~
site: sandpaper::sandpaper_site
---

<h2>Description</h2>

Fortran (a contraction of Formula Translation) was the first programming language to have a standard (in 1954), but has changed significantly over the years. More recent standards (the latest being Fortran 2023) come under the umbrella term "Modern Fortran". Fortran retains very great significance in many areas of scientific and numerical computing, particularly for applications such as quantum chemistry, plasmas, engineering and fluid dynamics, and in numerical weather prediction and climate models.

This intermediate course concentrates on some of the more recent features which are central to Modern Fortran. Attendees should be familiar with the basics of Fortran programming which might be covered in an introductory course, e.g., the one at,

<https://epcced.github.io/2026-03-02-Fortran-intro/>

So, attendees should be comfortable writing structured Fortran programs based on modules and procedures, and have a sound grounding in variables, logic, flow-of-control, and so on. Some knowledge of Fortran I/O is assumed.

There are two main topics in this intermediate course: the facilities in Fortran for abstraction and polymorphism provided by classes and interfaces, and the facilities for formal interoperability with ANSI C. The course will cover type extension ("classes" and "inheritance"), type-bound procedures ("methods"), generic procedures ("polymorphism"), and so on. The standard iso\_c\_binding module provides facilities for interoperability with C; this allow the communication of Fortran entities with direct analogues C, and also Fortran objects (particularly arrays) which have no direct analogue in C.

Further language features concerning arrays, pointers, and facilities for structured programming using submodules will also be covered along the way.

Knowledge of the object-oriented paradigm would be useful, but is not essential. Knowledge of C is required for the material on C/Fortran interoperation. The course will allow programmers interested in working on larger, structured, software projects to make use of (almost) a full complement of Modern Fortran features.

The course requires a Fortran compiler, for which a local machine or laptop may be appropriate [1]. If you do not have access to a Fortran compiler, course training accounts on ARCHER2 will be available which provide access to various compilers. Use of a text editor will be required (some may prefer an IDE, but we do not intend to consider or support IDEs).

[1] This may typically be gfortran, freely available as part of the GNU Compiler Collection (GCC). See e.g., <https://gcc.gnu.org/wiki/GFortranBinaries>

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

