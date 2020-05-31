---
title: Welcome to the blog!
pagination: 
    data: collections.posts
    alias: posts
    size: 5
    reverse: true
---

{%- for post in posts -%}
    <h3><a href={{post.url}}>{{post.data.title}}</a></h3>
    <p>{{post.data.description}}</p>
    <span class="badge badge-secondary">Posted {{ post.date | date: "%d %B %Y" }}</span>
    <hr>
    {{post.content}}
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
