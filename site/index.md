---
title: Welcome to the blog!
eleventyNavigation: 
    key: Home
    order: 1
pagination: 
    data: collections.posts
    size: 5
    alias: posts
---

{% for post in posts %}
- [{{post.data.title}}]({{post.url}})
{% endfor %}

{% if pagination.href.previous %}<a href="{{pagination.href.previous}}">Previous Page</a>{% endif %}
{% if pagination.href.next %}<a href="{{pagination.href.next}}">Next Page</a>{% endif %}