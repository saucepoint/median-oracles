# median-oracles
### **An experimental suite of Median Price Oracles via Uniswap v4 Hooks 🦄**

> *from ETHGlobal Paris 2023 / Arrakis Hookathon*

|                           | Gas   |
|---------------------------|-------|
| Quickselect               | 12345 |
| Frugal-2U                 | 12345 |
| Running Frugal-2U         | 12345 |
| Quickselect Time-weighted | TBD   |
| Frugal-2U Time-weighted   | TBD   |

> Methodology: obtain 50 unique tick observations by running swaps in both directions. Each swap is spaced 12 seconds apart. Use `gasleft()` before and after reading the median.

## Median Price Oracle (Quickselect)

## Frugal Median Price Oracle

## Running Frugal Median Price Oracle

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
│   ├── RunningFrugalMedianImplementation.sol
│   └── TickObserverImplementation.sol
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
