#userdata
locals {
  userdata_windows = <<-USERDATA
        <powershell>
        Invoke-WebRequest https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/windows_amd64/AmazonSSMAgentSetup.exe -OutFile $env:USERPROFILE\Desktop\SSMAgent_latest.exe
        Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore;
        Start-Process -FilePath $env:USERPROFILE\Desktop\SSMAgent_latest.exe -ArgumentList "/S"
        Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name inactivitytimeoutsecs -Value 0;
        New-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name Shadow -PropertyType dword -Value 4 -Force | out-null;
        New-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name disablepasswordsaving -PropertyType dword -Value 4 -Force | out-null;
        Set-Content -Value "New-Alias -Name grep -Value findstr.exe -Description 'grep alternative windows'" -Path $profile.AllUsersAllHosts;
        Enable-PSRemoting –force;
        Set-Service WinRM -StartMode Automatic;
        Set-Item WSMan:localhost\client\trustedhosts -value '*' -force;
        Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False;
        $policylocation = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System';
        $values = 'EnableLUA','ConsentPromptBehaviorAdmin','FilterAdministratorToken','LocalAccountTokenFilterPolicy';
        $values | foreach-object {Set-ItemProperty $policylocation -Name $_ -Value 0};
        (Get-WmiObject -class Win32_TSGeneralSetting -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0);
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        choco feature enable -n allowGlobalConfirmation
        choco upgrade powershell-core -y
        choco upgrade git -y
        choco upgrade notepadplusplus -y
        choco upgrade firefox -y
        choco upgrade 7zip -y 
        choco upgrade microsoft-windows-terminal -y
        choco upgrade python -y
        choco upgrade nssm -y
        RefreshEnv.cmd
        Install-WindowsFeature Web-Common-Http,Web-CGI,WinRM-IIS-Ext -IncludeAllSubFeature -IncludeManagementTools
        Set-Location "C:\"
        & 'C:\Program Files\Git\cmd\git.exe' clone 'https://github.com/spellingb/flask-aws-storage.git'
        git --version
        Set-Location 'C:\flask-aws-storage\'
        (Get-Content 'C:\flask-aws-storage\app.py') -replace 'lats-image-data','${aws_s3_bucket.img_mgr_bucket.bucket}' | set-content 'C:\flask-aws-storage\app.py' -force
        mkdir uploads
        $pipinstall = Start-Process 'C:\Python39\Scripts\pip3.exe' -ArgumentList 'install -r requirements.txt' -WorkingDirectory 'C:\flask-aws-storage' -PassThru
        do {
            sleep -s 5
        } until ($pipinstall.HasExited)
        nssm install ImgMgr 'C:\Python39\Scripts\flask.exe' 'run'
        nssm set ImgMgr AppDirectory 'C:\flask-aws-storage\'
        nssm start ImgMgr
        Stop-Service WAS -Force
        Invoke-WebRequest 'https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi' -OutFile "$env:TEMP\urlrewrite.msi"
        & "$env:TEMP\urlrewrite.msi" /quiet /norestart
        $urlrewrite = Start-Process "$env:TEMP\urlrewrite.msi" -ArgumentList "/quiet /norestart" -PassThru
        do {
            sleep -s 5
        } until ($urlrewrite.HasExited)
        Invoke-WebRequest 'https://go.microsoft.com/fwlink/?LinkID=615136' -OutFile "$env:temp\arr.msi"
        $arr = Start-Process "$env:temp\arr.msi" -ArgumentList "/quiet /norestart" -PassThru
        do {
            sleep -s 5
        } until ($arr.hasExited)
        & "$env:temp\arr.msi" /quiet /norestart
        Start-Service WAS
        Start-Service W3SVC
        & "$env:systemroot\system32\inetsrv\appcmd.exe" set apppool "DefaultAppPool" '-processModel.idleTimeout:"00:00:00"' /commit:apphost
        [System.Reflection.Assembly]::LoadFrom("$env:systemroot\system32\inetsrv\Microsoft.Web.Administration.dll") | Out-Null
        $manager = new-object Microsoft.Web.Administration.ServerManager
        $sectionGroupConfig = $manager.GetApplicationHostConfiguration()
        $sectionName = 'proxy';
        $webserver = $sectionGroupConfig.RootSectionGroup.SectionGroups['system.webServer'];
        if (!$webserver.Sections[$sectionName]){
            $proxySection = $webserver.Sections.Add($sectionName);
            $proxySection.OverrideModeDefault = "Deny";
            $proxySection.AllowDefinition="AppHostOnly";
            $manager.CommitChanges();
        }
        $manager = new-object Microsoft.Web.Administration.ServerManager
        $config = $manager.GetApplicationHostConfiguration()
        $section = $config.GetSection('system.webServer/' + $sectionName)
        $section.SetAttributeValue('enabled', 'true');
        $manager.CommitChanges();
        @'
        <?xml version="1.0" encoding="UTF-8"?>
        <configuration>
            <system.webServer>
                <rewrite>
                    <rules>
                        <rule name="Reverse Proxy to flask_img_mgr" stopProcessing="true">
                        <match url="(.*)" />
                        <conditions>
                            <add input="{CACHE_URL}" pattern="^(https?)://" />
                        </conditions>
                        <action type="Rewrite" url="{C:1}://127.0.0.1:5000/{R:1}" />
                        </rule>
                    </rules>
                </rewrite>
            </system.webServer>
        </configuration>
        '@ | Set-Content 'C:\inetpub\wwwroot\web.config' -Force
        Restart-Computer -Force
        </powershell>
    USERDATA
  userdata_linux = <<-USERDATA
        #!/bin/sh
        yum install -y git jq
        amazon-linux-extras install -y nginx1
        pip3 install pipenv
        echo "export PATH=\"\$PATH:/usr/local/bin"\" > localbin.sh
        cd ~ec2-user/
        cat > ~/.ssh/config << EOF
        Host *
            StrictHostKeyChecking no
        EOF
        chmod 600 ~/.ssh/config
        git clone https://github.com/spellingb/flask-aws-storage
        cd flask-aws-storage
        mkdir uploads
        chown -R ec2-user:ec2-user .
        cat > run.sh << EOF
        #!/bin/sh
        pipenv install
        pipenv run pip3 install -r requirements.txt
        REGION=\$(curl http://169.254.169.254/latest/meta-data/placement/region)
        IID=\$(curl http://169.254.169.254/latest/meta-data/instance-id)
        ENV=\$(aws --region \$REGION ec2 describe-tags --filters Name=resource-id,Values=\$IID | jq -r '.Tags[]|select(.Key == \"environment\")|.Value')
        FLASK_ENV=\$ENV pipenv run flask run
        EOF
        chmod 755 run.sh
        cat > /etc/systemd/system/imgmgr.service << EOF
        [Unit]
        Description=Image manager app
        After=network.target
        [Service]
        User=ec2-user
        WorkingDirectory=/home/ec2-user/flask-aws-storage
        ExecStart=/home/ec2-user/flask-aws-storage/run.sh
        Restart=always
        [Install]
        WantedBy=multi-user.target
        EOF
        sed -i s/lats-image-data/"${aws_s3_bucket.img_mgr_bucket.bucket}"/ app.py
        systemctl daemon-reload
        systemctl start imgmgr
        cat > /etc/nginx/conf.d/myapp.conf << EOF
        server {
        listen 80;
        server_name localhost;
        client_max_body_size 10M;
        location / {
                proxy_set_header Host \$http_host;
                proxy_pass http://127.0.0.1:5000;
            }
        }
        EOF
        systemctl restart nginx.service
        sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
        sudo yum install stress -y
        sudo yum install htop -y
    USERDATA
}
