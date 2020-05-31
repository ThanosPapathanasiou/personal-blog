---
pagination:
  data: collections
  size: 1
  alias: tag
  filter:
    - all
    - posts
permalink: /tags/{{ tag }}/
eleventyExcludeFromCollections: true
---

<h1>Posts with the tag “{{ tag }}”</h1>
<hr>

<ul class="list-group list-group-flush">
{% assign taggedposts = collections[tag] %}
{% for post in taggedposts -%}
    <li class="list-group-item">
        <h4><a href={{post.url}}>{{post.data.title}}</a></h4>
        <p>{{post.data.description}}</p>
        <div>
            <span class="badge badge-secondary">Posted {{ post.date | date: "%d %B %Y" }}</span>
            <div class="float-right">
                {%- for posttag in post.data.tags -%}
                {%- if posttag == tag -%}
                <a href="/tags/{{posttag}}" class="badge badge-pill badge-primary">{{posttag}}</a>
                {%- else -%}
                <a href="/tags/{{posttag}}" class="badge badge-pill badge-info">{{posttag}}</a>
                {%- endif %}
                {% endfor -%}
            </div>
        </div>
    </li>
{%- endfor -%}
</ul>