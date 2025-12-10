# Java 8 环境配置指南

## macOS 安装 Java 8

### 使用 Homebrew（推荐）
```bash
# 安装 Homebrew（如果没有）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 AdoptOpenJDK 8
brew install --cask temurin8

# 验证安装
java -version
```

### 手动下载安装
1. 访问 [AdoptOpenJDK](https://adoptium.net/temurin/releases/?version=8)
2. 下载 macOS x64 版本的 JDK
3. 安装并配置环境变量

## Linux 安装 Java 8

### Ubuntu/Debian
```bash
# 更新包列表
sudo apt update

# 安装 OpenJDK 8
sudo apt install openjdk-8-jdk

# 设置为默认版本
sudo update-alternatives --config java

# 验证安装
java -version
```

### CentOS/RHEL
```bash
# 安装 OpenJDK 8
sudo yum install java-1.8.0-openjdk-devel

# 或者使用 dnf (较新版本)
sudo dnf install java-1.8.0-openjdk-devel

# 设置环境变量
echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk' >> ~/.bashrc
source ~/.bashrc

# 验证安装
java -version
```

## Windows 安装 Java 8

1. 下载 [AdoptOpenJDK 8](https://adoptium.net/temurin/releases/?version=8&os=windows&arch=x64)
2. 运行安装程序
3. 配置环境变量：
   - `JAVA_HOME`: C:\Program Files\AdoptOpenJDK\jdk-8.x.x.x
   - `Path`: 添加 `%JAVA_HOME%\bin`

## 多版本 Java 管理

### 使用 jenv（macOS/Linux）
```bash
# 安装 jenv
brew install jenv

# 添加 Java 版本到 jenv
jenv add /usr/local/opt/openjdk@8/libexec/openjdk.jdk/Contents/Home
jenv add /usr/local/opt/openjdk@11/libexec/openjdk.jdk/Contents/Home
jenv add /usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home

# 列出所有版本
jenv versions

# 设置全局版本
jenv global 1.8

# 设置项目版本（在项目目录下）
jenv local 1.8
```

### 使用 SDKMAN!（跨平台）
```bash
# 安装 SDKMAN!
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# 安装 Java 8
sdk install java 8.0.382-tem

# 列出已安装版本
sdk list java

# 切换版本
sdk use java 8.0.382-tem

# 设置默认版本
sdk default java 8.0.382-tem
```

## 验证配置

启动项目前验证：
```bash
# 检查 Java 版本
java -version
# 输出应类似：openjdk version "1.8.0_xxx"

# 检查 JAVA_HOME
echo $JAVA_HOME

# 检查 Maven
mvn -version
```

## 常见问题

### Q: 检测到 Java 11+，但想使用 Java 8
A: 使用 jenv 或 sdkman 切换版本：
```bash
# jenv
jenv local 1.8

# SDKMAN!
sdk use java 8.0.382-tem
```

### Q: macOS 提示 "java cannot be opened"
A: 允许应用运行：
```bash
sudo xattr -r -d com.apple.quarantine /Library/Java/JavaVirtualMachines/temurin-8.jdk
```

### Q: Maven 仍然使用高版本 Java
A: 指定 JAVA_HOME：
```bash
export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
mvn -version
```

### Q: 编译错误：不支持 diamond operator
A: 确保编译器使用 Java 8：
```bash
mvn clean compile -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8
```

## 项目配置

项目已配置支持 Java 8：
- Spring Boot 版本：2.7.18（最后一个支持 Java 8 的 LTS 版本）
- 编译目标：Java 8
- 依赖项已调整为 Java 8 兼容版本

## 启动项目

确保 Java 8 环境后：
```bash
# 进入项目目录
cd workcheck-backend

# 启动服务
./start.sh start

# 或指定 Java 8 配置
./start.sh start -p java8
```