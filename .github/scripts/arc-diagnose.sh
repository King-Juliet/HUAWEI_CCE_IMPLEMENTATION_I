#!/usr/bin/env bash
# Prints what is needed to debug the ARC runner setup, straight into the pipeline log.
# Never fails the job - every command is best-effort.
set +e

section() { echo; echo "=================== $* ==================="; }

section "nodes";                         kubectl get nodes -o wide
section "all pods";                      kubectl get pods -A -o wide
section "recent events (last 80)";       kubectl get events -A --sort-by=.lastTimestamp | tail -n 80
section "ARC resources";                 kubectl get autoscalingrunnersets,autoscalinglisteners,ephemeralrunnersets,ephemeralrunners -A -o wide
section "describe pods in arc-runners";  kubectl describe pods -n arc-runners

for ns in arc-systems arc-runners; do
  for p in $(kubectl get pods -n "$ns" -o name 2>/dev/null); do
    section "logs $ns/$p (last 100 lines)"
    kubectl logs -n "$ns" "$p" --all-containers --tail=100
  done
done

exit 0