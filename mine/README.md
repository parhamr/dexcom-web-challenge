# Incremental Interquartile Mean

My approach: combined refactor for readability and performance optimization. I treated this like a processing library where the components are broken out for testing and ease of maintenance.

> Explain how your optimization works and why you took this approach

I reduced the algorithmic complexity by using a sorted insert. The Ruby implementation of sort uses the quicksort algorithm, which is known to be slower than necessary for nearly-sorted values. Since this processing class is expected to have an incremental approach, it is worth the added complexity to keep the data set sorted to gain a less expensive array insertion.

> Would your approach continue to work if there were millions or billions of input values?

Yes, it would continue to work, but the processing time would continue to get slower. I believe the `Fixnum` or `Float` values would expand to `Bignum` and `BigDecimal` as needed without a `TypeError`.

> Would your approach still be efficient if you needed to store the intermediate state between each IQM calculation in a data store? If not, how would you change it to meet this requirement?

I believe the IQM calculation should be able to continue to process up to the limit of allocatable memory on the processing machine.

An atomic data store representing the state as a singular value would likely find excessive write overhead and unnecessary churn in writing disk pages. I believe a data structure like a heap, queue, or sorted set would maintain a more desirable big-O complexity when compared to an array.


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