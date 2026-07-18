import Observation

@Observable class GlobalState {
    static let shared = GlobalState()
    var val = 0
}

var accessCount = 0

func testTracking() {
    withObservationTracking {
        _ = GlobalState.shared.val
    } onChange: {
        accessCount += 1
    }
}

testTracking()
GlobalState.shared.val = 1
print("Access count:", accessCount)
