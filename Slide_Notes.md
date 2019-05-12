# Slide Notes

**Slide 4**
The idea for the Let’s Encrypt Relay came about due to some issues we were facing in our environment with internal servers. We are always creating new servers for development and testing features. The pushback and delays that came with getting Internal SSL Certs was starting to effect the main reason we stood these up… to do testing. 

**Slide 5**
Being able to focus solely on testing is important so we thought about the main issues we were facing and came up with these four issues.

HSTS must be set and enabled for all servers, both internal and external
Requesting Internal SSL Certs required filling multiple forms out and waiting for someone to either reject them or approve them. Development Server requests always took the back seat
Internal SSL Certs didn’t work with most of the java applications we used
Purchasing SSL Certs from external CAs costs money, which requires approval and that usually doesn’t happen for development servers (it’s also a waste of money)

**Slide 6**
We were able to use the Let’s Encrypt Relay to find solutions for each of the issues we were facing.

HSTS can be configured and is no longer a four letter word when talking about internal servers
Using the Relay, users are in control of all of the SSL Certs they create. By taking out the requesting process and waiting for approvals, the focus can go back to testing and can start sooner then before
Let’s Encrypt SSL Certs are accepted and trusted with all of the java applications we use, which no longer limits what we can test before we have to start the long process of requesting an External SSL Cert
Let’s Encrypt SSL Certs are FREE.  The average for a 1 year SSL Cert is around $150. That can add up fast..

**Slide 8**
Besides solving the issues previously mentioned.. There are more benefits to using the Relay

I mentioned this in the previous slides, but it’s a big part of why I made the relay. It makes SSL Cert management extremely quick and easy, all due to the fact that each user is in charge of their own SSL Certs and can manage them by connecting to the Relay via SSH.
With the SSL Certs going through the Relay, there isn’t a need to open port 80 anymore. This not only increase security for internal servers (the less ports exposed the better!) but it also cut down on the number of firewall change requests being submitted (which I’m told made the group in charge of that pretty happy)
Being SSH Based, users can create scripts and playbooks to manage their SSL Certs. I don’t know a single Sys Admin out there who doesn’t love to automate something!
By using an SSH Wrapper script, we can limit the access normal users have when connecting to the Relay. 

**Slide 10**
These are the basic requirements to stand up a Let’s Encrypt Relay Server. I’m sure you could use a Windows Server instead or a different webserver, however.. I am more familiar with the above, which is why there were picked as the requirements.

For the server, I’m using CentOS 7 on an ESXI Host.

I mention the SSH Wrapper Script, Certmenu Script and the sshd_config here because they are the key pieces for the server side. I will be going over them more in detail later in this presentation.

**Slide 11**
In order for a user to use the relay, these two things have to happen.

The account being used to connect and manage the SSL Certs needs to exist on the Relay Server and the Public SSH Key needs to be stored on the Relay server as well.
Currently I am using an Ansible Playbook to create the user on the relay with a randomized password and copy the key over to it’s home directory. If your server is bound to AD and can publish Public SSH Keys, you can use an AD Security Group in the Match Group statement. Doing it this way eliminates the need for the account to exist on the Relay server prior to them using it. This is the direction I am going with ours when I get back.
To prove control of the domain being requested, the hostname for your internal server needs to be added as a CNAME to the Relay servers DNS Record on the public side. Its important that change only takes place on the PUBLIC side, if its added to the private side as well.. Both internal and external requests will go to the Relay server.

**Slide 13**
Now that we have gone over the requirements, Here is a high level overview of how the Relay handles incoming connections.

Using the account that manages their SSL Certs, the user connects to the Relay via SSH. The sshd_config checks if the user connecting is a member of the certbotusers group and runs the SSH Wrapper script if so.

The SSH Wrapper script looks at the connection request and filters it based off that. For example, if you are using scp to copy your SSL Certs over, it leaves it alone and allows the copy to start. Otherwise it will start the Certmenu script and pass any options that were entered when the SSH connection was established.

Once the action is finished, the connection to the Relay is automatically closed.  

**Slide 14**
If a user is a member of the certbotusers group, the SSH Wrapper Script takes over. 

I went with an SSH Wrapper due to the flexibility it allows without impacting security. In this slide, I have the SSH Wrapper script. You can see it’s nothing extremely complicated at all. You can also see the Certmenu script being referenced, which we will be going over next.

The SSH Wrapper script allows any incoming SCP or SFTP connections to continue without interacting with them. This allows users to easily copy their SSL Certs down when needed. 

If it sees the original SSH Command isn’t SCP or SFTP, it redirects the connection to the certmenu script and forwards the original command along with it

**Slide 15**
The certmenu script is what interacts with certbot and allows the users to create, renew or list their SSL Certs.

There are two ways to use the certmenu script, interactive or CLI. This gives the user several ways to manage their SSL Certs. In the example under the Interactive option, you can see the ssh connection request followed by what the user is looking to do. In this example, it’s create an SSL Cert. This triggers the interactive menus which I’ll go over during the examples.

In the example under the CLI option, you can see it starts off with the ssh connection request and is still followed with what the user is looking to do, however instead of just using the ‘create’ option, the hostname for the SSL Cert being created is also included. This is the option that allows users to automate these requests.

**Slide 16**
Here we can see the beginning of the certmenu script and how it takes the output of the SSH Wrapper Script and processes it for use.

The original ssh command is converted to all lowercase and saved to a variable (sshOption). I am converting everything to lowercase to make the case statement simpler.

You can also see the certbot variables being set on the lines below. This allows certbot to run in each user’s home directory, creating a sandbox just for their SSL Certs.

Now that everything is set, lets take a look at the case statement.

**Slide 17**
This is the case statement that runs the various options allowed. In the beginning I mentioned how the SSH Wrapper allows SCP and SFTP commands through but redirects anything else to the certmenu script. 

Options available:
- renew
- pfx (allows users to convert an existing SSL Cert for use with IIS)
- create
- help
- list

This case statement will look at the sslOutput variable and match it to one of these options. If the variable doesn’t match any of the allowed options, it will call a function containing script usage then exit with an error code of 1. 

This section also helps restrict access and usage so we can keep the relay and everyone’s SSL Certs safe.

**Slide 18**
Now that we have gone through the two main scripts, we need to  configure sshd_config so it filters users correctly. 

We can do this by adding a Match Group conditional block to the sshd_config. You can see we are defining three options inside the Match Group section. 

PasswordAuthentication
- Because we already have the user’s public SSH Key, we are disabling the option for passwords to be used. This also helps us control who has access to the Relay and avoids managing passwords.
ForceCommand
- This will automatically run the SSH Wrapper Script and forward the original SSH command being used
AuthorizedKeysFile
- This sets the location of where the public SSH keys are stored. Adding this option allows the keys to be stored in a non-default location and only contain the keys for the relay users
