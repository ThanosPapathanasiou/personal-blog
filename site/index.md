---
title: Welcome to my blog!
pagination: 
    data: collections.posts
    alias: posts
    size: 5
    reverse: true
---

Hi! My name is Thanos and this is my blog.

It contains my observations on ~~a lot~~ some of the things I tinker with. The ones I managed to convince myself to actually sit down and document.

Hopefully you'll find something useful here.

#### Here's my latest blog posts:
<hr>
{% for post in posts -%}
    <h4><a href={{post.url}}>{{post.data.title}}</a></h4>
    <p>{{post.data.description}}</p>
    <div>
        <span class="badge badge-secondary">Posted {{ post.date | date: "%d %B %Y" }}</span>
        <div class="float-right">
            {%- for tag in post.data.tags -%}
            <a href="/tags/{{tag}}" class="badge badge-pill badge-info">{{tag}}</a>
            {% endfor -%}
        </div>
    </div>
    <hr>
{%- endfor -%}

<ul class="pagination justify-content-center mb-4">
    {%- if pagination.href.previous -%}
    <li class="page-item">
        <a class="page-link" href="{{pagination.href.previous}}">← Older</a>
    </li>
    {%- else -%}
    <li class="page-item disabled">
        <a class="page-link" href="#">← Older</a>
    </li>
    {%- endif -%}
    {%- if pagination.href.next -%}
    <li class="page-item">
        <a class="page-link" href="{{pagination.href.next}}">Newer →</a>
    </li>
    {%- else -%}
    <li class="page-item disabled">    
        <a class="page-link" href="#">Newer →</a>
    </li>
    {%- endif -%}
</ul>
