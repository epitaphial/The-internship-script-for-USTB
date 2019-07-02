#!/bin/bash
# author:Curled
# date:2019/7/1

mkdir -p /var/log/autoins_404
datevar=`date`
nowdate=`echo "vital_log${datevar:24}_${datevar:4:3}_${datevar:0:3}"`
echo -e  "\033[36m_________________________________________________________\033[0m"
echo -e "\033[35m|	 _____                _  _    ___  _  _         |\033[0m"
echo -e "\033[31m|	| ____|_   _____ _ __| || |  / _ \| || |        |\033[0m"
echo -e "\033[32m|	|  _| \ \ / / _ \ '__| || |_| | | | || |_       |\033[0m"
echo -e "\033[33m|	| |___ \ V /  __/ |  |__   _| |_| |__   _|      |\033[0m"
echo -e "\033[34m|	|_____| \_/ \___|_|     |_|  \___/   |_|        |\033[0m"
echo -e "|						        |"
echo -e  "\033[36m---------------------------------------------------------\033[0m"
echo "	USTB认识实习自动化部署脚本"
echo "	Powered by Ever404"
echo "	auth by Curled"
echo "	生产环境：centos7.0+"
echo "	当前系统时间："`date`|tee -a /var/log/autoins_404/${nowdate}.log
echo "请输入："
echo "1.开始部署"
echo "2.退出"
echo "__________________________________________________________"
echo ""
read input
if [[ $input = "2" ]];then
	echo "bye~"
	exit
elif [[ $input != "1" ]];then
	echo "输入非法！"
	exit
elif [ ! -n "$input" ];then
	echo "输入为空！"
	exit
fi
if [[ `whoami` != "root" ]];then
	echo "请先root！"
	exit
fi
echo "开始部署……"
sleep 1
trap   "部署过程中不要按CTRL C和Z哦"  INT QUIT  TSTP
#系统更新
yum -y update
yum -y upgrade

#创建非root用户
echo "开始创建非root用户……"
while :
do
	read -p "请输入要创建的用户名:" username
	if [ ! -n "$username" ];then
		echo "输入不能为空！"
	else
		break
	fi
done
grep $username  /etc/passwd > /dev/null
if [ $? -eq 0 ]; then
	echo "用户${username}已存在！跳过"
	sleep 1
else
	adduser $username
	definePasswd=`echo $RANDOM |md5sum|cut -c 1-8`
	echo ${definePasswd} | passwd --stdin ${username}
	echo  用户名:${username} 密码: ${definePasswd} >> /home/savePasswd.log
	echo "成功创建用户：$username"|tee -a /var/log/autoins_404/${nowdate}.log
	echo "md5随机密码已保存至 /home/savePasswd.log,按任意键继续！"|tee -a /var/log/autoins_404/${nowdate}.log
	read stopkey
	
	#加入sudoer组
	cp /etc/sudoers /etc/sudoers.bak
	chmod -v u+w /etc/sudoers
	echo "${username}  ALL=(ALL)       ALL" >> /etc/sudoers
	usermod -g root ${username}
	echo "用户${username}已加入sudoer用户组"
fi

#java开发环境安装
echo "开始配置JDK环境……"|tee -a /var/log/autoins_404/${nowdate}.log
jdkv=`java -version`
if [[ ! -n "$jdkv" ]];
then
	sleep 1
	yum -y install java-1.8.0-openjdk
	yum -y install java-devel
	echo "当前java版本为"|tee -a /var/log/autoins_404/${nowdate}.log
	echo `java -version`
	echo `javac -version`
	echo "测试java……"
	echo 'class a{public static void main(String[]args){System.out.println("javaok");}}'>a.java
	javac a.java
	output=`java a`
	if [[ ${output} = "javaok" ]];then
		echo "Java环境配置成功！"|tee -a /var/log/autoins_404/${nowdate}.log
		rm a.*
		sleep 1
	else
		echo -e "\033[31mJava环境配置失败，请稍后手动检查环境变量！\033[0m"|tee -a /var/log/autoins_404/${nowdate}.log
		sleep 2
	fi
else
	echo "您已安装过JDK环境，版本为：$jdkv"|tee -a /var/log/autoins_404/${nowdate}.log
	sleep 1
fi
#maven环境配置
mvnve=`mvn -v`
if [[ ! -n "$mvnve" ]];
then
	echo "开始配置maven"|tee -a /var/log/autoins_404/${nowdate}.log
	sleep 1
	wget https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.1/binaries/apache-maven-3.6.1-bin.tar.gz
	mkdir /usr/local/maven3
	tar zvxf apache-maven-3.6.1-bin.tar.gz
	mv apache-maven-3.6.1/* /usr/local/maven3
	echo 'export M2_HOME=/usr/local/maven3'>>/etc/profile
	echo 'export PATH=$PATH:$JAVA_HOME/bin:$M2_HOME/bin'>>/etc/profile
	source /etc/profile
	rm -rf apache-maven-3.6.1*
	mvnve=`mvn -v`
	if [[ ! -n "$mvnve" ]];
	then
		echo -e "\033[31m安装maven失败，请稍后手动检查环境变量\033[0m"|tee -a /var/log/autoins_404/${nowdate}.log
		sleep 1
	else
		echo "maven安装成功"|tee -a /var/log/autoins_404/${nowdate}.log
		echo "maven版本为："`mvn -v`|tee -a /var/log/autoins_404/${nowdate}.log
		echo ""
		sleep 1
	fi
else
	echo "您已安装maven，版本为:"`mvn -v`|tee -a /var/log/autoins_404/${nowdate}.log
	echo ""
	sleep 1
fi

#SVN环境配置
svner=`svn --version`
if [[ ! -n "$svner" ]];
then
	echo "开始安装SVN……"|tee -a /var/log/autoins_404/${nowdate}.log
	yum -y install subversion
	svner=`svn --version`
	if [[ ! -n "svner" ]];then
		echo -e "\033[31mSVN安装失败，请稍后手动检查环境变量\033[0m"|tee -a /var/log/autoins_404/${nowdate}.log
		sleep 1
	else
		echo "SVN安装成功，版本为："`svn --version`|tee -a /var/log/autoins_404/${nowdate}.log
		echo ""
		sleep 1
		
	fi
else
	echo "您已安装SVN，版本为："`svn --version`|tee -a /var/log/autoins_404/${nowdate}.log
	echo ""
	sleep 1
fi

#mysql环境配置

maraer=`rpm -qa|grep mariadb`
if [[  -n "$maraer" ]];
then
	echo "卸载原有的mariadb-lib……"|tee -a /var/log/autoins_404/${nowdate}.log
	rpm -e mariadb-libs --nodeps
fi
myer=`mysql -V`
if [[ ! -n "$myer" ]];
then
	echo "开始安装mysql……"|tee -a /var/log/autoins_404/${nowdate}.log
	sleep 1
	wget https://repo.mysql.com//mysql80-community-release-el7-3.noarch.rpm
	rpm -ivh mysql80-community-release-el7-3.noarch.rpm
	yum -y install yum-utils
	yum-config-manager --disable mysql80-community
	yum-config-manager --enable mysql57-community
	yum -y install mysql-community-server
	myer=`mysql -V`
	systemctl start mysqld.service
	if [[ ! -n "$myer" ]];
	then
		echo -e "\033[31mmysql安装失败，请稍后手动检查源！\033[0m"|tee -a /var/log/autoins_404/${nowdate}.log
	else
		initpass=`grep 'temporary password' /var/log/mysqld.log`
		echo "mysql安装成功！初始密码为：${initpass}"|tee -a /var/log/autoins_404/${nowdate}.log
		rm mysql80-community-release-el7-3.noarch.rpm
	fi
else
	echo "您已经安装过mysql，版本为："`mysql -V`|tee -a /var/log/autoins_404/${nowdate}.log
	echo ""
	sleep 1
fi

#redis环境配置
reder=`redis-cli --version`
if [[ ! -n "$reder" ]];
then
	echo "开始安装redis……"|tee -a /var/log/autoins_404/${nowdate}.log
	yum install -y http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
	yum -y --enablerepo=remi install redis
	systemctl start redis
	reder=`redis-cli --version`
	if [[ ! -n "$reder" ]];
	then
		echo -e "\033[36m安装失败，请稍后自行检查源\033[0m"|tee -a /var/log/autoins_404/${nowdate}.log
		sleep 1
	else
                echo "您已成功安装redis，版本为：$reder"|tee -a /var/log/autoins_404/${nowdate}.log
		echo ""
		sleep 1
                systemctl enable redis.service	
	fi
else
	echo "您已安装redis，版本为：$reder"|tee -a /var/log/autoins_404/${nowdate}.log
	echo ""
fi

#tomcat环境配置
echo "开始安装tomcat……"|tee -a /var/log/autoins_404/${nowdate}.log
tomv=`/usr/local/tomcat/apache-tomcat-9.0.21/bin/version.sh`
if [[ ! -n "tomv" ]];
then
	mkdir /usr/local/tomcat
	wget https://mirrors.aliyun.com/apache/tomcat/tomcat-9/v9.0.21/bin/apache-tomcat-9.0.21.tar.gz
	tar -xzvf apache-tomcat-9.0.21.tar.gz
	rm apache-tomcat-9.0.21.tar.gz
	mv apache-tomcat* /usr/local/tomcat
	firewall-cmd --zone=public --add-port=8080/tcp --permanent
	firewall-cmd --reload
	cd /usr/local/tomcat/apache-tomcat-9.0.21/bin/
	./startup.sh
	echo "tomcat 已安装完毕，请访问ip:端口，若外网不能访问，请检查实例安全组是否添加8080端口"|tee -a /var/log/autoins_404/${nowdate}.log
	echo "您的tomcat版本为："` /usr/local/tomcat/apache-tomcat-9.0.21/bin/version.sh`|tee -a /var/log/autoins_404/${nowdate}.log
	sleep 1
else
	echo "您已安装tomcat，版本为：$tomv"|tee -a /var/log/autoins_404/${nowdate}.log
	sleep 1
fi
echo "------------------------------------------------------"
echo "  __   _           _         _       _ "
echo " / _| (_)  _ __   (_)  ___  | |__   | |"
echo "| |_  | | | '_ \  | | / __| | '_ \  | |"
echo "|  _| | | | | | | | | \__ \ | | | | |_|"
echo "|_|   |_| |_| |_| |_| |___/ |_| |_| (_)"
echo "______________________________________________________"
echo "所有的服务都已部署完毕！完结撒花~"
echo "若在使用过程中有任何疑惑或者错误信息，请查看/var/log/autoins_404/目录下的日志文件~"
