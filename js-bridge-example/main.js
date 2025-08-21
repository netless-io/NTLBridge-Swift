import { bridge } from "@netless/webview-bridge";

window.bridge = bridge;

function addBtn(title, action) {
  const btn = document.createElement("div");
  btn.className = "btn";
  btn.onclick = action;
  btn.innerText = title;
  document.body.appendChild(btn);
}

addBtn("Synchronous call", callSyn);
addBtn("Asynchronous call", callAsyn);
addBtn("Sync call without argument", callNoArgSyn);
addBtn("Async call without argument", callNoArgAsyn);
addBtn("echo.syn", echoSyn);
addBtn("echo.asyn", echoAsyn);
addBtn("Stress test，2K times consecutive asynchronous API calls", callAsyn_);
addBtn(
  "Never call because without @JavascriptInterface annotation<br/>( This test is just for Android ,should be ignored in IOS )",
  callNever
);

function alert(param) {
  console.log(param);
  document.getElementById("log").innerText = param;
}

// Initialize WebView Bridge from @netless/webview-bridge
function callSyn() {
  console.log("call sync");
  const result = bridge.syncCall("testSyn", "Hello");
  alert(result);
}

function callAsyn() {
  bridge
    .asyncCall("testAsyn", "hello")
    .then((result) => {
      alert(result);
    })
    .catch((err) => {
      alert("Error: " + err.message);
    });
}
function callAsyn_() {
  let completed = 0;
  for (let i = 0; i < 2000; i++) {
    bridge
      .asyncCall("testAsyn", "js+" + i)
      .then((result) => {
        completed++;
        if (completed === 2000) {
          alert("All tasks completed!");
        }
      })
      .catch((err) => {
        alert("Error: " + err.message);
      });
  }
}

function callNoArgSyn() {
  const result = bridge.syncCall("testNoArgSyn");
  alert(result);
}

function callNoArgAsyn() {
  bridge.asyncCall("testNoArgAsyn").then((result) => {
    alert(result);
  });
}

function callNever() {
  bridge
    .call("testNever", { msg: "testSyn" })
    .then((result) => {
      alert(result);
    })
    .catch((err) => {
      alert("Error: " + err.message);
    });
}

function echoSyn() {
  const reulst = bridge.syncCall("echo.syn", { msg: "I am echoSyn call", tag: 1 });
  alert(reulst);
}

function echoAsyn() {
  bridge
    .asyncCall("echo.asyn", { msg: "I am echoAsyn call", tag: 2 })
    .then((result) => {
      alert(result);
    });
}

// Register JavaScript methods
bridge.register("addValue", (r, l) => {
  return r + l;
});

bridge.registerAsync("append", (arg1, arg2, arg3) => {
  return Promise.resolve(arg1 + " " + arg2 + " " + arg3);
});

bridge.registerAsync("startTimer", () => {
  return new Promise((resolve) => {
    let t = 0;
    const timer = setInterval(() => {
      if (t === 5) {
        resolve(t);
        clearInterval(timer);
      } else {
        resolve(t++);
      }
    }, 1000);
  });
});

// Register namespace methods
bridge.register("syn", {
    tag: (param) => { console.log("fff", param); return "v1"; },
    multi: (p1, p2) => { console.log(p1, p2); return { p1, p2}; },
    error: (param) => {
      console.log("error", param);
      const error = new Error("This is a test synchronous error");
      const structuredError = {
            name: error.name,
            message: error.message,
            code: error.code || 'UNKNOWN',
            stack: error.stack,
      }
      console.log(structuredError);
      console.log(JSON.stringify(structuredError));
      throw error;
    }
});
bridge.registerAsync("asyn", {
    tag: (param, callback) => { 
        console.log("tag", param);
        setTimeout(() => {
            callback({value: 222});
        }, 1000);
    },
    error: async (param, callback) => {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      throw new Error("This is a test asynchronous error");
    },
    multiParam: (p1, p2, callback) => {
        console.log("multiparam", p1, p2);
        setTimeout(() => {
            callback({value: 444, p1, p2});
        }, 1000);
    }
});