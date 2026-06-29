from enum import Enum, auto


class State(Enum):
    Red = auto()
    Green = auto()
    Yellow = auto()


class TrafficLight:
    def __init__(self):
        self.cycles = 0
        self.pedestrian = False
        self.state = State.Red
        self._enter_Red()

    def _enter_Red(self):
        self.cycles = (self.cycles + 1)
        self.pedestrian = False

    def _exit_Red(self):
        pass

    def _enter_Green(self):
        pass

    def _exit_Green(self):
        pass

    def _enter_Yellow(self):
        pass

    def _exit_Yellow(self):
        pass

    def send(self, event, **kwargs):
        handler = getattr(self, f"_on_{event}", None)
        if handler is None:
            print(f"Unknown event: {event}")
            return False
        return handler(**kwargs)

    def _on_tick(self):
        if self.state == State.Red:
            if True:
                self._exit_Red()
                self._enter_Green()
                self.state = State.Green
                return True
        if self.state == State.Green:
            if self.pedestrian:
                self._exit_Green()
                self.pedestrian = False
                self._enter_Yellow()
                self.state = State.Yellow
                return True
        if self.state == State.Green:
            if (not self.pedestrian):
                self._exit_Green()
                self._enter_Yellow()
                self.state = State.Yellow
                return True
        if self.state == State.Yellow:
            if True:
                self._exit_Yellow()
                self._enter_Red()
                self.state = State.Red
                return True
        return False

    def _on_pushButton(self):
        if self.state == State.Green:
            if True:
                self._exit_Green()
                self.pedestrian = True
                self._enter_Green()
                self.state = State.Green
                return True
        return False


if __name__ == "__main__":
    m = TrafficLight()
    _v = {'cycles': m.cycles, 'pedestrian': m.pedestrian}
    print(f"start: state={m.state.name} vars={_v}")
    m.send("tick")
    _v = {'cycles': m.cycles, 'pedestrian': m.pedestrian}
    print(f"after tick: state={m.state.name} vars={_v}")
    m.send("pushButton")
    _v = {'cycles': m.cycles, 'pedestrian': m.pedestrian}
    print(f"after pushButton: state={m.state.name} vars={_v}")
    m.send("tick")
    _v = {'cycles': m.cycles, 'pedestrian': m.pedestrian}
    print(f"after tick: state={m.state.name} vars={_v}")
    m.send("pushButton")
    _v = {'cycles': m.cycles, 'pedestrian': m.pedestrian}
    print(f"after pushButton: state={m.state.name} vars={_v}")
    m.send("tick")
    _v = {'cycles': m.cycles, 'pedestrian': m.pedestrian}
    print(f"after tick: state={m.state.name} vars={_v}")
    m.send("pushButton")
    _v = {'cycles': m.cycles, 'pedestrian': m.pedestrian}
    print(f"after pushButton: state={m.state.name} vars={_v}")
