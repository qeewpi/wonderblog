---
title: Creating my blog with Obsidian, the Zettelkasten System, and Hugo
date: 2025-11-15
draft: false
tags: []
---
*Took me a while, but here I am, documenting my entire process – from my note-taking system to the creation of my blog. Hopefully this comes helpful to anyone who may come across this.*
## Obsidian
A few months ago I began utilizing Obsidian for my note-taking. It initially served my needs sufficiently. However, it came to a point where I felt a need for a more "concrete" system – one that essentially allowed me to have a "wiki" for my knowledge as well as improve my ability to synthesize new ideas.

I came across the concept of the Zettelkasten system through [Odyseas' video](https://www.youtube.com/watch?v=hSTy_BInQs8), where he provides an in-depth guide on how he set up his note-taking system in Obsidian. Since then, I've been using this system, with just the slightest alterations to fit my workflow.

### The Setup for the Blog 
I created a new folder in my vault labeled "Posts". The name is pretty self-explanatory – this is where I will be storing all my blogposts. 

![[Pasted image 20251115130838.png]]

In the near future, I plan on improving the integration of Hugo with Obsidian through [oscarmlage's](https://oscarmlage.com/posts/hugo-and-obsidian/) method.

For now, let's keep things simple.
## Hugo
The idea of creating a blog to publish my write-ups has been looming in my mind since forever. A multitude of events have gotten in the way, but, alas, I'm *finally* getting to it.

While working on a side project, I watched Den Delimarsky's video on the GitHub Spec Kit. In the video, he used his own [blog](https://den.dev/) as a demonstration. I was in awe at how seamless his process for content creation was – through it, I discovered Hugo. 

For a long time, I've been planning to have a simple and straight-forward solution for my blog. As I was already utilizing Obsidian, being able to publish through the Markdown format was especially crucial to my ideal workflow. Hugo fit the criteria perfectly, at this point, it was a *no-brainer* decision.
### Prerequisites
- Go
- Git

### Setting up the directory

I created a new folder for my Hugo website, within that I made sure to create a "src" folder to store the actual contents.

```powershell
mkdir "C:\Users\Ashley-PC\Documents\wonderblog"
cd "C:\Users\Ashley-PC\Documents\wonderblog"
mkdir src
```

### Installation

I was facing issues setting up Docker on my Windows machine, thus, I decided to proceed with installing (using `Chocolatey`) and running Hugo directly on my machine.

```powershell
choco install hugo-extended
```

### Create a new site

With in the `src` directory, I initialized a new Hugo site.

```powershell
hugo new site .
```

### Creating the Git repository

```powershell
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/qeewpi/wonderblog.git
git push -u origin main
```

### Installing Congo theme

I followed the installation steps from the [Congo repository](https://github.com/jpanther/congo) as well as configured the theme to my liking.

### Syncing Obsidian with Hugo

To sync the "Posts" folder from my Obsidian vault to the project directory `content/posts` folder, I utilized `mklink`.

```powershell
mklink /D "C:\Users\Ashley-PC\Documents\wonderblog\src\content\posts" "C:\Users\Ashley-PC\Documents\Ashley in Wonderland\Posts"
```




