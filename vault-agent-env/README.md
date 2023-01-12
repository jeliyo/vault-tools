# vault-agent-env

This was a hackweek demo for March 2022.

Overview: https://github.com/hashicorp/rad-hackathon-march-2022/issues/50

These are the repos that I modified:
* https://github.com/hashicorp/vault
* https://github.com/hashicorp/vault-k8s
* https://github.com/hashicorp/consul-template
* https://github.com/jasonodonnell/vault-agent-demo

In this directory are diff patches with my changes, named with the
repo they came from, and the SHA they are based off. (Didn't want to
push branches just yet, since this isn't really ready for public
:eyes: yet, and I didn't want to leave a bunch of stale branches
around.

I got as far as Agent acting like an "init" container would today,
auth, render secret templates, and exit. Except instead of exiting, it
syscall.Exec's the app.

# Demo Notes (Fri Mar 11 2022)

  - Intro:
    - vault-agent today can render templated secrets to files using
      consul-template
    - lots of users/customers want secrets in env variables for their
      apps (12-factor and all that)
    - there's a secrets injector making the rounds called "piggy" that
      works with AWS SM, instead of sidecars, using a process wrapper
      to populate environment variables with secrets, then starts the
      app
    - so I took a stab at making vault-agent into this style of
      process wrapper that could auth, render secrets to env vars, and
      start up the app
    - i think the end goal would be a vault agent that auths, renders,
      launches the app, then keeps the auth token alive, and also
      renews secrets and restarts the app if secrets change.

  - Demo steps:
    - show new annotations
    - run and patch
    - port-forward and show webpage
    - show pod yaml with init container and app/agent run line
    - show empty /vault/secrets, and jq /home/vault/config.json

  - nice things about this:
    - secrets in environment variables (12-factor app)
    - secrets aren't set in Kubernetes Secrets, or anywhere outside the Pod
    - same auth methods and templating as normal injector, no expanded
      permissions required

  - bonus:
    - could still write secrets to files... anywhere in the app
      container (java properties)
    - could more easily restart an app if secrets change

  - cons
    - multiple binaries in a container
    - no more separation between agent and the app
    - issues with fs permissions, running as a different user, etc.
    - don't have an actual "vault" container running so it may not
      register on the container stats lists
