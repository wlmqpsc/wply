# What is WPLY

The name WPLY mix WordPress and Lychee together

## About WordPress and Lychee

### WordPress

[wordpress.org](https://wordpress.org/)

>WordPress (WP or WordPress.org) is a free and open-source content management system (CMS) written in hypertext preprocessor (PHP) language and paired with a MySQL or MariaDB database with supported HTTPS.

### Lychee

[lycheeorg.github.io](https://lycheeorg.github.io/)

>Lychee is a free photo-management tool, which runs on your server or web-space. Installing is a matter of seconds. Upload, manage and share photos like from a native application. Lychee comes with everything you need and all your photos are stored securely.

## Why WPLY

WordPress is likely to be the initial choice for many personal websites. I opted for Lychee to provide image hosting services while using a combination of WordPress and Lychee to build my blog. However, during the process of setting up and maintaining my blog server, I discovered that both these platforms may introduce different versions of PHP simultaneously. Site migration is a challenging task, and it also becomes inconvenient to backup, maintain and manage.

To reduce server costs and simplify maintenance, I created this project.

This project uses Docker to provide the environment and deploy services, and most of the services are containerized. You can easily and quickly deploy and run them on any server with support for automatic deployment, backup, recovery, and other functions. Additionally, data can be imported from an existing website. In just a few seconds, you can have a cloned version of a website up and running.
