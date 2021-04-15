---
layout: default
title: Tags
permalink: /tags/
description: "kyryl horbushko - posts indexed by tags"
---

<div id="tags">
{% assign sorted_tags = site.tags | sort %}
    <h2>All tags</h2>
        <p>
        {% for tag in sorted_tags %}
            <a class="post-tag" href="{{ site.baseurl }}/tags/#{{ tag[0] | slugify }}">{{ tag[0] }}</a>
        {% endfor %}
        </p>
    <h2>Posts by tags</h2>
    {% for tag in sorted_tags %}
        <div id="{{ tag[0] | slugify }}">
            <h3>{{ tag[0] }}</h3>
            {% for post in tag[1] %}
                <ul>
                       <a class="post-link-tags" href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
               </ul>
            {% endfor %}
        </div>
    {% endfor %}
</div>
