from enum import Enum, auto


class State(Enum):
    Idle = auto()
    Collecting = auto()
    Dispensing = auto()
    Refunding = auto()


class VendingMachine:
    def __init__(self):
        self.balance = 0
        self.price = 75
        self.dispensed = False
        self.returnCoins = 0
        self.state = State.Idle
        self._enter_Idle()

    def _enter_Idle(self):
        self.balance = 0
        self.dispensed = False
        self.returnCoins = 0

    def _exit_Idle(self):
        pass

    def _enter_Collecting(self):
        pass

    def _exit_Collecting(self):
        pass

    def _enter_Dispensing(self):
        self.dispensed = True

    def _exit_Dispensing(self):
        self.returnCoins = ((self.balance - self.price) // 5)
        self.balance = (self.balance - self.price)

    def _enter_Refunding(self):
        self.returnCoins = (self.returnCoins + (self.balance // 5))
        self.balance = (self.balance - ((self.balance // 5) * 5))

    def _exit_Refunding(self):
        pass

    def send(self, event, **kwargs):
        handler = getattr(self, f"_on_{event}", None)
        if handler is None:
            print(f"Unknown event: {event}")
            return False
        return handler(**kwargs)

    def _on_coin(self, value):
        if self.state == State.Idle:
            value = value
            if (value > 0):
                self._exit_Idle()
                self.balance = (self.balance + value)
                self._enter_Collecting()
                self.state = State.Collecting
                return True
        if self.state == State.Collecting:
            value = value
            if (value > 0):
                self._exit_Collecting()
                self.balance = (self.balance + value)
                self._enter_Collecting()
                self.state = State.Collecting
                return True
        return False

    def _on_select(self):
        if self.state == State.Collecting:
            if ((self.balance >= self.price) and (not self.dispensed)):
                self._exit_Collecting()
                self._enter_Dispensing()
                self.state = State.Dispensing
                return True
        if self.state == State.Collecting:
            if (self.balance < self.price):
                self._exit_Collecting()
                self._enter_Collecting()
                self.state = State.Collecting
                return True
        if self.state == State.Dispensing:
            if True:
                self._exit_Dispensing()
                self._enter_Idle()
                self.state = State.Idle
                return True
        return False

    def _on_cancel(self):
        if self.state == State.Collecting:
            if ((self.balance > 0) or self.dispensed):
                self._exit_Collecting()
                self._enter_Refunding()
                self.state = State.Refunding
                return True
        return False


if __name__ == "__main__":
    m = VendingMachine()
    _v = {'balance': m.balance, 'price': m.price, 'dispensed': m.dispensed, 'returnCoins': m.returnCoins}
    print(f"start: state={m.state.name} vars={_v}")
    m.send("coin", value=50)
    _v = {'balance': m.balance, 'price': m.price, 'dispensed': m.dispensed, 'returnCoins': m.returnCoins}
    print(f"after coin: state={m.state.name} vars={_v}")
    m.send("select")
    _v = {'balance': m.balance, 'price': m.price, 'dispensed': m.dispensed, 'returnCoins': m.returnCoins}
    print(f"after select: state={m.state.name} vars={_v}")
    m.send("cancel")
    _v = {'balance': m.balance, 'price': m.price, 'dispensed': m.dispensed, 'returnCoins': m.returnCoins}
    print(f"after cancel: state={m.state.name} vars={_v}")
    m.send("coin", value=50)
    _v = {'balance': m.balance, 'price': m.price, 'dispensed': m.dispensed, 'returnCoins': m.returnCoins}
    print(f"after coin: state={m.state.name} vars={_v}")
    m.send("select")
    _v = {'balance': m.balance, 'price': m.price, 'dispensed': m.dispensed, 'returnCoins': m.returnCoins}
    print(f"after select: state={m.state.name} vars={_v}")
    m.send("cancel")
    _v = {'balance': m.balance, 'price': m.price, 'dispensed': m.dispensed, 'returnCoins': m.returnCoins}
    print(f"after cancel: state={m.state.name} vars={_v}")
    m.send("coin", value=50)
    _v = {'balance': m.balance, 'price': m.price, 'dispensed': m.dispensed, 'returnCoins': m.returnCoins}
    print(f"after coin: state={m.state.name} vars={_v}")
    m.send("select")
    _v = {'balance': m.balance, 'price': m.price, 'dispensed': m.dispensed, 'returnCoins': m.returnCoins}
    print(f"after select: state={m.state.name} vars={_v}")
    m.send("cancel")
    _v = {'balance': m.balance, 'price': m.price, 'dispensed': m.dispensed, 'returnCoins': m.returnCoins}
    print(f"after cancel: state={m.state.name} vars={_v}")
