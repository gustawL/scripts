#!/usr/bin/env python3
# seccomp template
import seccomp

f = seccomp.SyscallFilter(defaction=seccomp.ALLOW)

CLONE_NEWUSER = 0x10000000

f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "ptrace")
f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "userfaultfd")
f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "bpf")
f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "perf_event_open")
f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "kcmp")
f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "process_vm_readv")
f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "process_vm_writev")
f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "mount")
f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "umount2")
f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "pivot_root")
f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "chroot")

f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "unshare",
           seccomp.Arg(0, seccomp.MASKED_EQ, CLONE_NEWUSER, CLONE_NEWUSER))

f.add_rule(seccomp.ERRNO(seccomp.errno.EPERM), "clone",
           seccomp.Arg(0, seccomp.MASKED_EQ, CLONE_NEWUSER, CLONE_NEWUSER))

f.add_rule(seccomp.ERRNO(seccomp.errno.ENOSYS), "clone3")

with open("filter.bpf", "wb") as out:
    f.export_bpf(out)
