# median-oracles
### **An experimental suite of Median Price Oracles via Uniswap v4 Hooks 🦄**

> *from ETHGlobal Paris 2023*

|                           | Gas (Read)                              |
|---------------------------|---------------------------------------- |
| Quickselect               | comically a lot (hundreds of thousands) |
| Frugal-2U                 | comically a lot (hundreds of thousands) |
| Running Frugal-2U         | 4812                                    |
| Quickselect Time-weighted | TBD                                     |
| Frugal-2U Time-weighted   | TBD                                     |

> Methodology: obtain 50 *unique* tick observations by running swaps in both directions. Each swap is spaced 12 seconds apart. Use `gasleft()` before and after reading the median.

## Median Price Oracle (Quickselect)

The classic median: given a sequence of unordered fetch the median with the quickselect algorithm

* Uses the quickselect algorithm
* Depends on tick observations in storage

## Frugal Median Price Oracle

The naive implementation of [RunningFrugalMedian](#running-frugal-median-price-oracle): approximate the median using `Frugal-2U` from a sequence of numbers.

Frugal median algorithm compares new numbers against the current approximation and updates the approximation according to a dynamic *step*

* Uses the frugal median-approximation algorithm
* Depends on tick observations in storage

## Running Frugal Median Price Oracle

The gas-optimized implementation of the frugal median approximation: calculating an on-going approximation of the median

* Uses the frugal median-approxiation algorithm
* Stores the *running* median (approximated) in directly storage
* *additional research™️ required for windowed support* 

### Future work: step-optimization
In the frugal median algorithm, the dynamic *step* can be modified to favor stabilization or responsiveness/accuracy. The repo uses 1-tick as a step, but the implementation is set up for additional experimentation

### Future work: time-weighted medians

The repo is in its early stages and did not have sufficient time to implement time-weighted medians. Time-weighted medians are likely to better represent the price since they account for the duration of a tick (price observation). The repo currently treats unique price observations as having equivalent durations.


---


```
src/
├── RunningFrugalMedianHook.sol - Running median approximation
├── TickObserver.sol - store tick observations for windowed median reads
├── lens
│   ├── FrugalMedianLens.sol - read TickObserver and approximate median
│   └── MedianLens.sol - read TickObserver and calculate true median
└── lib
    ├── FrugalMedianLibrary.sol - median approximation library
    ├── MedianLibrary.sol - median calculation library (quickselect)
    └── RingBufferLibrary.sol - optimized ring buffer for price observations

test/
├── FrugalMedianLens.t.sol
├── MedianLens.t.sol
├── RunningMedian.t.sol
├── TickObserver.t.sol
├── implementation
│   ├── ... - Uniswap overrides for testing
├── median
│   ├── FrugalMedianTest.t.sol - test frugal median algo
│   └── MedianLibrary.t.sol - test quickselect algo
└── utils
    ├── HookTest.sol
    └── RingBuffer.t.sol - test ring buffer
```

---

Additional resources:

[v4-periphery](https://github.com/uniswap/v4-periphery) contains advanced hook implementations that serve as a great reference

[v4-core](https://github.com/uniswap/v4-core)

---

*requires [foundry](https://book.getfoundry.sh)*

```
forge install
forge test
```

---

Credits

* [Frugal Streaming for Estimating Quantiles:One (or two)
memory suffices](https://arxiv.org/pdf/1407.1121v1.pdf)

* [euler-xyz/median-oracle] and [median oracle discussions]

* [Uniswap TWAP analysis]