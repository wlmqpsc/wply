# 什么是 WPLY

WPLY 的取名来源于 WordPress 和 Lychee

## 关于 WordPress 和 Lychee

### WordPress

[wordpress.org](https://wordpress.org/)

>WordPress（简称WP或WordPress.org）是一款免费开源的内容管理系统(CMS)，用Hypertext Preprocessor（PHP）语言编写，配合MySQL或MariaDB数据库，支持HTTPS协议。

### Lychee

[lycheeorg.github.io](https://lycheeorg.github.io/)

>Lychee是一款免费的照片管理工具，可以在您的服务器或网络空间上运行。其安装仅需几秒钟，可以像使用本地应用程序一样上传、管理和分享照片。Lychee自带了所有您需要的功能，并确保所有照片都得到安全存储。

## 为什么使用 WPLY

WordPress可能是许多人的第一个个人网站。我使用Lychee来提供图床服务，我的博客则是采用了WordPress和Lychee结合的方式搭建。然而，在部署和维护我的博客服务器的过程中，我发现它们可能会同时引入不同的PHP版本。网站迁移变得非常困难，备份、维护和管理也不方便。

为了节约服务器成本，减少维护工作，我创建了这个项目。

这个项目使用docker来提供环境并部署服务，大部分服务都是容器化的，您可以放心地在任何一台服务器上快速部署并运行，支持自动部署、自动备份、自动恢复等功能，您还可以从现有的网站导入数据。仅需几秒，你就可以得到一个网站的克隆版本。
