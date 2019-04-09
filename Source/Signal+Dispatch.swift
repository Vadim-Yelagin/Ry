import Foundation

public extension Signal {
    private struct DispatchState {
        let item: DispatchWorkItem
        let block: VoidClosure
    }

    static func dispatch(
        value: T,
        qos: DispatchQoS = .default,
        flags: DispatchWorkItemFlags = [],
        on dispatcher: @escaping (DispatchWorkItem) -> Void) -> Signal
    {
        return Signal { observer in
            let atomic = UnfairAtomic<DispatchState?>(nil)
            let item = DispatchWorkItem(qos: qos, flags: flags) {
                atomic.swap(nil)?.block()
            }
            atomic.value = DispatchState(item: item) { observer.observe(value) }
            dispatcher(item)
            return Disposable { [weak atomic] in
                atomic?.swap(nil)?.item.cancel()
            }
        }
    }

    func dispatch(
        qos: DispatchQoS = .default,
        flags: DispatchWorkItemFlags = [],
        on dispatcher: @escaping (DispatchWorkItem) -> Void) -> Signal
    {
        return mergeMap {
            .dispatch(value: $0, qos: qos, flags: flags, on: dispatcher)
        }
    }

    func onMainThread() -> Signal {
        return mergeMap { value in
            Thread.isMainThread
                ? .value(value)
                : .dispatch(value: value, on: DispatchQueue.main.async)
        }
    }

    func delay(by timeInterval: DispatchTimeInterval,
               on queue: DispatchQueue = .main,
               qos: DispatchQoS = .default,
               flags: DispatchWorkItemFlags = []) -> Signal {
        return dispatch(qos: qos, flags: flags) { item in
            queue.asyncAfter(deadline: .now() + timeInterval, execute: item)
        }
    }
}
