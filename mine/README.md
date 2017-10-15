# Incremental Interquartile Mean


## Original Implementation

Output: `100000: 458.82`

### Timings

Best

```
real  8m55.872s
user  7m56.622s
sys 0m16.779s
```

Worst:

```
real  9m30.587s
user  8m1.203s
sys 0m26.761s
```

## My Implementation

Output: `100000: 458.82`

### Timings


First pass:

```
real  5m44.284s
user  4m47.272s
sys 0m21.876s
```

Improvements…

Sorted insert:
```
real	1m7.617s
user	0m26.990s
sys	0m37.405s
```