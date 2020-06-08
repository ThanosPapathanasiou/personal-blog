---
title: Setting up eleventy to work with github pages
description: A simple static site generator so you can finally start blogging with your free github page.
date: 2020-05-31
tags:
    - eleventy
    - static-site-generation
    - github-pages
---

Ever since github started offering their GitHub Pages to use as a personal website for its users, I've been interested in using them. I've even tried setting mine up a couple of times but I always found that configuring jekyll and finding a proper theme that would play well with whatever versions of rubygems I already had was a pain. 

Furthermore, there was no reason in my mind to have yet another development environment (Ruby's) installed on my local machine and kept up to date so that I could write a blog post once in a blue moon. 

So, in the end, I never bothered with actually using my github page for quite some time.

I do tend prioritize things lower if there is significant friction when doing something with them and blogging with the github pages had quite a bit of friction involved.

It had been going like that for a while until a few days ago when I came across a youtube video about [setting up a static site with eleventy.][1] The tool seemed to get out of your way as much as possible and allowed you to simply write your markdown files to be processed into pages. 

Within a few minutes I was convinced. I started yet again the process of setting up my github page and working with eleventy to create a decent static page as output.

Everything was working just fine and dandy until the time came to actually have github host the pages that eleventy outputs. There were alot of websites documenting how to do this process but I found them to be either too complicated (setup github actions, CI servers, etc) or the result would not be clean enough (have the eleventy static site output commited to the same repository as the code).

In the end, there was this [blogpost by Tom Hiskey][2] that mentioned in the TLDR:

```If you're trying to deploy an Eleventy site to GitHub Pages, one option is to build it locally and fiddle about with settings.```

But, as I already mentioned, I don't want to mix my static site (the output) with the code that is responsible for that (the input)

So I did the following:

1. Create a base directory, let's call it "blog"
2. Inside that directory we'll clone the github page, [thanospapathanasiou.github.io][3]
3. And we will also initialize another git folder called [personal-blog][4]

Our folder structure will end up being like this:

``` 
./blog/
./blog/thanospapathanasiou.github.io (git repository 1)
./blog/personal-blog/ (git repository 2)
```

With this folder structure, you can start writing your blogposts in the personal-blog folder and have eleventy running and serving them locally for any tweeks you might need to do before you commit them. 

Be careful though. If you want to keep things clean and separated like I do then you don't want to commit the static html output in the personal-blog folder, you want to commit them to your github page. 

The problem is that copying and pasting the changes from codingblog/_site/* to thanospapathanasiou.github.io/* can be such a pain.

Thankfully the good ol' Makefile comes to the resque! This is the [one][5] I wrote for my purposes.

You basically need three things:

1. Clean the codingblog/_site/* so you start from an empty base. 
``` bash
rm -rf _site/*
```

2. Build your eleventy static site into codingblog/_site/* 
``` bash
npx @11ty/eleventy eleventy --input=site --output=_site
```

3. finally, we need to copy that static file into our github pages folder.

    1. First we need to clean up the github pages folder
    ```
    find ../thanospapathanasiou.github.io/ -mindepth 1 ! '(' -path '../thanospapathanasiou.github.io/.git/*' -or -name '.git' -or -name 'CNAME' ')' -delete
    ```

    2. Copy the output to the github page folder
    ```
    cp -a ./_site/. ../thanospapathanasiou.github.io/
    ```

Step 3.1 is a bit complicated so let's break it down a bit. 

Basically what we need to do is find all the items in the github page directory that are **NOT** in its .git folder, are not the actual .git folder itself, or the CNAME file (that's the file that has the custom domain name your blog will point to)

Now my proccess from creating a new blogpost is quite straightforward and with a lot less friction!

1. Create a folder with the blogpost's permalink in the ```/personal-blog/site/blog``` folder.
Let's say that the name of that folder is ```setting-up-eleventy-to-work-with-github-pages```
2. Create a ```index.md``` file and start writing
3. Open a terminal in the ```/personal-blog/``` folder and run ```make run```
4. Have your browser navigate to ```http://localhost:8080``` and watch it for anything not displaying correctly
5. Once you are done with editing, run ```make publish``` and the changes will appear in the github directory
6. Commit and push the changes from both repositories
7. Profit?

I've found that the above proccess works really well for me, if you want to have a look at the repository for yourself then the link is [here][4]

Happy blogging!

[1]: https://www.youtube.com/watch?v=j8mJrhhdHWc
[2]: https://tomhiskey.co.uk/posts/deploying-eleventy-to-github-pages-one-way/
[3]: https://github.com/ThanosPapathanasiou/thanospapathanasiou.github.io
[4]: https://github.com/ThanosPapathanasiou/personal-blog
[5]: https://github.com/ThanosPapathanasiou/personal-blog/blob/master/Makefile