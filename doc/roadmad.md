# Roadmap 

17.nov.2025:
TODO: Cleanup use of tmpdir 
TMPDIR in env points to  /var/folders/9w/tt305cd54dz5ktqzh82t4tvw0000gp/T/ on my MAc


9.nov.2025: s
TODO: Update to reflect change back to port forwarding .


Last updated 04-NOV-2025. 

As of version 0.7 the functionality is at a satisfactory level. 

The goal has all along been to have a very simple code base that is similar for remote SSH and 
other tools (mysqlsh, sqlcl, etc). 
There will be a slight departure from this gioal with re-introduction of fucntionality for Managed SSH Bsstion sesions.
This is to support the patalell efforts with InnoDB Cluster configuration via `pyinfra`. 

Remaining pieces to be done **before** releasing as 1.0: 

- <del> Clean up code according to modern best practices (0.7)</del>
- Add support for managed bastion ssh sessions (0.8)
    - New-OpuManagedSshSessionFull
    - Wait-OpuBastionPluginRunning 

- Add examples of using utilities inside of GitHub runners (0.8)

- Add tests using pester (1.0)