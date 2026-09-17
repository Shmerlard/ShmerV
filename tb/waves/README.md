# Surfer layouts

Save reusable unit-test Surfer state files here as `<test>.surf.ron`.

CPU-system layouts can be program-specific at
`cpu_system/<program>.surf.ron`. When a program-specific layout does not exist,
`cpu_system.surf.ron` is used as the shared fallback.

When neither a matching layout nor shared fallback exists, `just sim` and
`just wave` create a default layout at the program- or module-specific path.

The `just sim` and `just wave` commands load the matching state file automatically when it exists.
