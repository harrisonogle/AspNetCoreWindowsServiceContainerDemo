# Containerized ASP.NET Core app as a (non-admin) Windows service

This is a POC for running an ASP.NET Core app under a non-administrator account by deploying it as a Windows service.

NOTE: The Docker `ENTRYPOINT` executable still runs as admin. This is required to

- launch Geneva monitoring agent (set up ETW)
- move certificates from file mounts into the appropriate certificate store(s)
- any thing else that requires admin strictly at runtime (not during build time)

That's fine according to Microsoft, as long as the entrypoint isn't network-connected.

[Secure Windows containers | Microsoft Learn](https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/container-security)
> If the design of a container allows for an elevated (admin) process to interact with the host,
> then Microsoft does not consider this container to have a robust security boundary.

Also see the [section on Windows services](https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/container-security#windows-services).

> Microsoft Windows services, formerly known as NT services, enable you to create long-running executable applications that run in their own Windows sessions. These services can be automatically started when the operating system starts, can be paused and restarted, and do not show any user interface. You can also run services in the security context of a specific user account that is different from the logged-on user or the default computer account.
> 
> When containerizing and securing a workload that runs as a Windows service there are a few additional considerations to be aware of. First, the ENTRYPOINT of the container is not going to be the workload since the service runs as a background process, typically the ENTRYPOINT will be a tool like service monitor) or log monitor). Second, the security account that the workload operates under will be configured by the service not by the USER directive in the dockerfile. You can check what account the service will run under by running Get-WmiObject win32_service -filter "name='<servicename>'" | Format-List StartName.
> 
> For example, when hosting an IIS web application using the ASP.NET (Microsoft Artifact Registry) image the ENTRYPOINT of the container is "C:\\ServiceMonitor.exe", "w3svc". This tool can be used to configure the IIS service and then monitors the service to ensure that it remains running and exits, thus stopping the container, if the service stops for any reason. By default, the IIS service and thus the web application run under a low privilege account within the container, but the service monitor tool requires administrative privileges to configure and monitor the service.

# Running the demo

- Clone the repo.
- Open a new DOS terminal. (cmd.exe)
- `cd` into the directory containing `Entrypoint.csproj`
- Run the following commands
    1. `build.cmd` to build the docker container
    2. `run.cmd` to run the docker container
    3. `exec.cmd` (optionally) to execute commands within the running container
- The service is exposed on the host machine on port 5000. Try the endpoints:
    - `http://localhost:5000/`
    - `http://localhost:5000/user`

The `GET /user` endpoint displays the Windows identity the service is running under,
and whether or not it is an administrator.
