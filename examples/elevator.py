from enum import Enum, auto


class State(Enum):
    Idle = auto()
    MovingUp = auto()
    MovingDown = auto()
    DoorOpen = auto()


class Elevator:
    def __init__(self):
        self.floor = 0
        self.target = 0
        self.doorOpen = False
        self.state = State.Idle
        self._enter_Idle()

    def _enter_Idle(self):
        self.doorOpen = False

    def _exit_Idle(self):
        pass

    def _enter_MovingUp(self):
        pass

    def _exit_MovingUp(self):
        pass

    def _enter_MovingDown(self):
        pass

    def _exit_MovingDown(self):
        pass

    def _enter_DoorOpen(self):
        self.doorOpen = True

    def _exit_DoorOpen(self):
        pass

    def send(self, event, **kwargs):
        handler = getattr(self, f"_on_{event}", None)
        if handler is None:
            print(f"Unknown event: {event}")
            return False
        return handler(**kwargs)

    def _on_request(self, dest):
        if self.state == State.Idle:
            dest = dest
            if (dest > self.floor):
                self._exit_Idle()
                self.target = dest
                self._enter_MovingUp()
                self.state = State.MovingUp
                return True
        if self.state == State.Idle:
            dest = dest
            if (dest < self.floor):
                self._exit_Idle()
                self.target = dest
                self._enter_MovingDown()
                self.state = State.MovingDown
                return True
        if self.state == State.Idle:
            dest = dest
            if (dest == self.floor):
                self._exit_Idle()
                self._enter_DoorOpen()
                self.state = State.DoorOpen
                return True
        if self.state == State.DoorOpen:
            dest = dest
            if (dest > self.floor):
                self._exit_DoorOpen()
                self.target = dest
                self._enter_MovingUp()
                self.state = State.MovingUp
                return True
        if self.state == State.DoorOpen:
            dest = dest
            if (dest < self.floor):
                self._exit_DoorOpen()
                self.target = dest
                self._enter_MovingDown()
                self.state = State.MovingDown
                return True
        if self.state == State.DoorOpen:
            dest = dest
            if (dest == self.floor):
                self._exit_DoorOpen()
                self._enter_DoorOpen()
                self.state = State.DoorOpen
                return True
        return False

    def _on_step(self):
        if self.state == State.MovingUp:
            if (self.floor < self.target):
                self._exit_MovingUp()
                self.floor = (self.floor + 1)
                self._enter_MovingUp()
                self.state = State.MovingUp
                return True
        if self.state == State.MovingUp:
            if (self.floor == self.target):
                self._exit_MovingUp()
                self._enter_DoorOpen()
                self.state = State.DoorOpen
                return True
        if self.state == State.MovingDown:
            if (self.floor > self.target):
                self._exit_MovingDown()
                self.floor = (self.floor - 1)
                self._enter_MovingDown()
                self.state = State.MovingDown
                return True
        if self.state == State.MovingDown:
            if (self.floor == self.target):
                self._exit_MovingDown()
                self._enter_DoorOpen()
                self.state = State.DoorOpen
                return True
        return False


if __name__ == "__main__":
    m = Elevator()
    _v = {'floor': m.floor, 'target': m.target, 'doorOpen': m.doorOpen}
    print(f"start: state={m.state.name} vars={_v}")
    m.send("request", dest=50)
    _v = {'floor': m.floor, 'target': m.target, 'doorOpen': m.doorOpen}
    print(f"after request: state={m.state.name} vars={_v}")
    m.send("step")
    _v = {'floor': m.floor, 'target': m.target, 'doorOpen': m.doorOpen}
    print(f"after step: state={m.state.name} vars={_v}")
    m.send("request", dest=50)
    _v = {'floor': m.floor, 'target': m.target, 'doorOpen': m.doorOpen}
    print(f"after request: state={m.state.name} vars={_v}")
    m.send("step")
    _v = {'floor': m.floor, 'target': m.target, 'doorOpen': m.doorOpen}
    print(f"after step: state={m.state.name} vars={_v}")
    m.send("request", dest=50)
    _v = {'floor': m.floor, 'target': m.target, 'doorOpen': m.doorOpen}
    print(f"after request: state={m.state.name} vars={_v}")
    m.send("step")
    _v = {'floor': m.floor, 'target': m.target, 'doorOpen': m.doorOpen}
    print(f"after step: state={m.state.name} vars={_v}")
