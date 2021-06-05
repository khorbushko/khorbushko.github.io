---
layout: post
comments: true
title: "Select git branching model"
categories: article
tags: [git]
excerpt_separator: <!--more-->
comments_id: 47

author:
- kyryl horbushko
- Lviv
---

Hot to organize u'r code in the git? How efficiently use git and control app source code?. This and a few more questions can be asked before starting any new project.
<!--more-->

Today, we have a lot of git branching models. Which to choose? Well, it depends... I would like to tell here about few models that I often use on my projects.

## Intro

There are a lot of git branching models. 

Often we can choose one of the existing models for our project, but, sometimes it's not very suitable (due to team composition or some other preferences).

I mostly used few branching models:

- Git-flow (with modification)
- Trunk-based development model
- Single master / GitHub Flow

## Git Installation

There are several ways to install Git on a Mac. In fact, if you've installed XCode (or it's Command Line Tools), Git may already be installed. To find out, open a terminal and enter `git --version`.

>`$ git --version`
>
>`$ git version 2.7.0 (Apple Git-66)`

Apple actually maintains and ship their own fork of Git, but it tends to lag behind mainstream Git by several major versions. You may want to install a newer version of Git using one of the methods below:

If u haven't installed git yet:

- Open your terminal and install Git using Homebrew:
 
> `$ brew install git`

- Verify the installation was successful by typing which git --version:
 
> `$ git --version git version 2.9.2`

- Configure your Git username and email using the following commands, replacing Emma's name with your own. These details will be associated with any commits that you create:

> `$ git config --global user.name "Emma Paris" `
> 
> `$ git config --global user.email "eparis@atlassian.com"`

- *(Optional)* To make Git remember your username and password when working with HTTPS repositories, install the [git-credential-osxkeychain helper](https://www.atlassian.com/git/tutorials/install-git#install-the-git-credential-osx).

[More about git](https://git-scm.com/)

## Git-flow (simplified)

During work within git, one of the most popular is a [system created by Vincent Diessen](http://nvie.com/posts/a-successful-git-branching-model/). We develop a bit simplified flow.

U can also use [git-flow](http://jeffkreeftmeijer.com/2010/why-arent-you-using-git-flow/) for semi-automated work with git. Few more [rules needed for git-flow](http://danielkummer.github.io/git-flow-cheatsheet/index.uk_UK.html).

> Here is a perfect [guide from the author](https://nvie.com/posts/a-successful-git-branching-model/)

### Main principles

Git-flow - set of extensions for git, that helps follow [system created by Vincent Diessen](http://nvie.com/posts/a-successful-git-branching-model/).

#### Main architecture for branches:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/architecture.png" alt="architecture.png" width="450"/>
</div>
<br>
<br>

> instead of `master` u can name this branch for example as `main`

### Initialization

The whole work will be done in 2 main branches:

- `master`
- `develop`

Assuming we starting from empty git, so we need to init `master` branch.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/master.png" alt="architecture.png" width="450"/>
</div>
<br>
<br>

At the very beggining, we should add `.gitignore` file into this branch. To generate this file we can use some service like [gitignore.io](gitignore.io).

> Check out current [file](../../.gitignore).

Then based on `master` we can create `develop` branch. Based on this branch we will prepare any builds and populate code into `release/` folder.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/master_develop.png" alt="architecture.png" width="450"/>
</div>
<br>
<br>

### Tasks

#### Features

Features start from `develop` branch. Any new functionality should be created from `develop` branch and move into `feature/` folder, then switch to this branch and proceed with changes.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/develop_feature.png" alt="architecture.png" width="450"/>
</div>
<br>
<br>

> Note: make sure u correctly name the folder 
> 
> ✅ `feature/`
> 
> ❌ `features/`

Any UI should be captured by screenshot or gif and described states.

Unit/UI tests are **mandatory**.

> Note: checkmark `Remove search branch when a merge request is accepted` should be checked and merged branch should be removed from git.

#### Bugs

In general rules for `bug` is the same as for `feature` except the name of the folder.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/develop_bug.png" alt="architecture.png" width="450"/>
</div>
<br>
<br>

> Note: make sure u correctly name the folder 
> 
> ✅ `bug/`
> 
> ❌ `bugs/`

To complete `bug` perform the same steps as for `feature`

#### Hotfix

In general rules for `hotfix` is the same as for `feature` except the name of the folder and a fact that this branch can be created either from `release/` folder's branches either from `develop`

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/hotfix.png" alt="hotfix" width="450"/>
</div>
<br>
<br>

> Note: make sure u correctly name the folder 
> 
> ✅ `hotfix/`
> 
> ❌ `hotFix/` or `hotfixes/`

To complete `bug` perform the same steps as for `feature`

___
### Create `release/`'s branches

As soon as the build from `develop` branch is prepared and tested, the source build's commit may become **release candidate**. So we must put a tag on the build's commit and if the build goes to release we should create from its branch in `release/` folder.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/build.png" alt="build" width="450"/>
</div>
<br>
<br>

> Note: `build` on the scheme is just a process step - no branches required here.

> Note: make sure u correctly name the folder 
> 
> ✅ `release/`
> 
> ❌ `releases/`


When release proceeds by Store, we should create merge request to master, so master will always refer to latest version of production code.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/master_merge.png" alt="master_merge" width="450"/>
</div>
<br>
<br>

As result, git will store all `tags` for all builds, and folder `release/` will contains all releases.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/git.png" alt="git" width="750"/>
</div>
<br>
<br>

> Note: CI can create direct push in to develop branch - for bumping build version.

___
### Branch naming rules

When u name a branch follow the next rules:

- format 

	`PREFIX(optional)/NUMBER-OF-TASK - short_branch_name_or_description (optional)`
	
> 
> ✅ `feature/OXI-3232` or `feature/OXI-3232 - my_functionality`
> 
> ❌ `my_functionality` or `features/OXI-3232`

User prefix for diffent task type:


|prefix|branch|description|
|-|-|-|
|feature|develop|for feature task|
|bug|develop|for bug task|
|hotfix|develop or release's|for hotfix task|

### Practival usage

There is a lot of discussions related to git-flow during last time. And indeed, this model becomes obsolete.

Here is the good *"Note of reflection"* from the Author of git-flow ():

> This model was conceived in 2010, now more than 10 years ago, and not very long after Git itself came into being. In those 10 years, git-flow (the branching model laid out in this article) has become hugely popular in many software teams to the point where people have started treating it like a standard of sorts — but unfortunately also as a dogma or panacea.
> 
> (March 5, 2020) [source](https://nvie.com/posts/a-successful-git-branching-model/)


## The Trunk-based development model

The second model that I would like to represent - is **The Trunk-based development model**. The one, used by [Google](https://cloud.google.com/architecture/devops/devops-tech-trunk-based-development) developers.

If we look at the description of this model (we can refer to one of the [guide](https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development) related to this):

> *Trunk-based development* is a version control management practice where developers merge small, frequent updates to a core “**trunk**” or **main** branch. Since it streamlines merging and integration phases, it helps achieve CI/CD and increases software delivery and organizational performance.
> 	
> **Gitflow**, which was popularized first, is a stricter development model where only certain individuals can approve changes to the main code. This maintains code quality and minimizes the number of bugs. 
> 
> **Trunk-based development** is a more open model since all developers have access to the main code. This enables teams to iterate quickly and implement CI/CD.

Trunk-based development is a version control management practice where developers merge small, frequent updates to a core “**trunk**” or **main** branch.

This model simplifies the usage of the CI/CD practices.

When finite and small iteration of development (usually a few commits only) are done, merge requests created to the “**trunk**” or **main** branch. Before merging this merge request, developers should be sure that:

* the code is buildable
* no known bugs are added
* tests for new code added and succeed

### Trunk - main principles

To understand this model, it's better to compare it with an alternative - feature-branching model:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/feachureBranching.png" alt="feachureBranching.png" width="650"/>
</div>
<br>
<br>

In comparison to this model, trunk-based can be represented as:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/trunk-based.png" alt="trunk-based.png" width="650"/>
</div>
<br>
<br>

**Main principles are:**

* All branches can leave at maximum for 2-3 days
* continuous code review
* feature flag (we should be able to enable/disable the feature by enabling/disabling flag).
* **main** - always ready to deploy

##### Feature flagging

Few more words about feature flags - such a way allows us to deploy code that is not yet ready and also share the code between non-ready features. 

The practice of feature flagging (pioneered by Martin Fowler), or wrapping new features in code that can be remotely toggled on and off, is one common development process that software engineers employ to help to implement trunk-based development while reducing the risk of introducing bugs into the code.

This model provides also a few **benifits**:

* reduce conflicts while merging the code
* improve speed and reduce the difficulty of the code review process
* deliver new functionality as quick as possible
* reduce the complexity of git branches
* reduce amount of frizzed code
* share the code and knowledge
* early feedback to code
* improves the[ development speed](https://trunkbaseddevelopment.com/game-changers/index.html#google-revealing-their-monorepo-trunk-2016)

**Disadvantages** also present in this model

* it's hard to use for inexperienced developers
* hard to track error in commits
* works badly if to a big team
* not appropriate if there are a lot of junior developers in a team
* not best case for open-source projects

## Single master/ GitHub Flow

In [2011 GitHub](http://scottchacon.com/2011/08/31/github-flow.html) created GitHub Flow - flow created in a way, that allows making ad deploy at any time. That's the main idea - all processes created around this purpose.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/gitFlow.png" alt="gitFlow.png" width="650"/>
</div>
<br>
<br>

### Main principles

- branching is a main concept
- **main** branch is always deployable
- all branches can leave at a maximum for a 2-3 days
- continuous code review

### How it's work

Here is a quote from the authors of the GitHub Flow:

- Anything in the master branch is deployable
- To work on something new, create a descriptively named branch off of master (ie: new-oauth2-scopes)
- Commit to that branch locally and regularly push your work to the same-named branch on the server
- When you need feedback or help, or you think the branch is ready for merging, open a pull request
- After someone else has reviewed and signed off on the feature, you can merge it into master
- Once it is merged and pushed to ‘master’, you can and should deploy immediately

### Feature

It's also good to mention, that everything is based on branches - _commit message is very important_. Commits create a history, commits helps developers to navigate and to work with git. Always remember this.

The maximum existing branch - up to 2 days. Thankfully this, amount of code to be review can be minimized and so this process very quick and efficient.

### Merge

When a feature is done - the pull (merge) request should be opened. Thus this model is tightly coupled with CI/CD, automatic testing and code quality checks should be present and done every time after creating.

Discussion and review of the code - are also very important. Such a principle allows to share the knowledge about the code and to improve the logic behind it.

> use MD format for pull request comments, to make them more readable and efficient.

When a pull request is merged - the process starts from the beginning.

Pull Requests preserve a record of the historical changes to your code. Because they're searchable, they let anyone go back in time to understand why and how a decision was made.

### Bug

Bugs - an essential part of any development. How they handled within this model? In the same way as we handle features: single branch, short lifetime, open di

> Read more - official guide [here](https://guides.github.com/introduction/flow/)

### Release

The release can be done at any moment from any commit from **main** branch. When it's done, an appropriate tag should be added to the branch.

### Visual representation

Visual representation is sometimes much easier to understand. So here is the visual representation of this model:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/single-main.png" alt="single-main.png" width="750"/>
</div>
<br>
<br>

## Git Commit messages rules

Git Commit Message Guidelines The rules of a great git commit message:

* Capitalize the subject line

	> For example:
	> 
	> ✅ Accelerate to 88 miles per hour
	> 
	> Instead of:
	> 
	> ❌ accelerate to 88 miles per hour


* Do not end the subject line with a period
	> Example:
	>
	> ✅ Open the pod bay doors
	>
	> Instead of:
	>
	> ❌ Open the pod bay doors.
	
* Use the imperative mood in the subject line

	> For example:
	> 
	>  ✅ Refactor subsystem X for readability Update getting started documentation Remove deprecated methods Release version 1.0.0
	> 
	> Instead of:
	> 
	>  ❌ Fixed bug with Y Changing the behavior of X More fixes for broken stuff Sweet new API methods
	> 
	> Because:
	> 
	> - If applied, this commit will refactor subsystem X for readability
	> - If applied, this commit will update getting started documentation
	> - If applied, this commit will remove deprecated methods
	> - If applied, this commit will release version 1.0.0
	> - If applied, this commit will merge pull request #123 from user/branch

* Limit the subject line to 50 characters
> Example: a truncated message on GitHub web-site (length > 50)
  
<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-06-10-select-git-branching-model/message.png" alt="message.png" width="450"/>
</div>
<br>
<br>

* Wrap the body at 72 characters Git never wraps text automatically.

* Separate subject from body with a blank line Example: One line message
	`$ git commit -m"Fix typo in introduction to user guide”`
	
	>  ✅ Example: Multiple lines message
	> 
	>  
 MCP turned out to be evil and had become intent on world
	 domination.
	 This commit throws Tron's disc into MCP (causing its deresolution)
	 and turns it ba
	>
	>  ✅ Example: Multiple lines message log as one line
	`$ git log --oneline
	 42e769 Derezz the master control program`


* Use the body to explain what and why vs. how

* Separate title and body with symbol `>`:

	> Example:
	>
	> ✅ INV-3232 > update localization for dependents flow
	>
	> Instead of:
	>
	> ❌ update localization.

## Resources

* [What is Your Branching Model?](https://paulhammant.com/2013/12/04/what_is_your_branching_model/)
* [Trunk-based development](https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development)
* [Google Trunk-based development](https://cloud.google.com/architecture/devops/devops-tech-trunk-based-development)
* [Trunk-based Development vs. Git Flow](https://www.toptal.com/software/trunk-based-development-git-flow)
* [What is Trunk Based Development? A Different Approach to the Software Development Lifecycle](https://www.freecodecamp.org/news/what-is-trunk-based-development/)
* [Trunk-Based Development](https://www.optimizely.com/optimization-glossary/trunk-based-development/)
* [A successful Git branching model](https://nvie.com/posts/a-successful-git-branching-model/)
* [Git hub flow](http://scottchacon.com/2011/08/31/github-flow.html)
* [Understanding the GitHub flow](https://guides.github.com/introduction/flow/)
