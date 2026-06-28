// 用C++模拟Mesa Monitor
#import "/template.typ":*
#doc-template(
title: "用C++模拟Mesa Monitor",
date: "2019年6月20日",
body: [

Monitor（管程）是并发程序的同步方式之一。Monitor至少有两类，Mesa monitor和Hoare monitor。Mesa monitor在notify之后会继续运行，Hoare monitor在notify之后会进行context switch，来到wait的地方开始运行，所以在写wait的时候，Mesa monitor需要这样：

```cpp
while (locked)
    wait();
```

但是Hoare Monitor只需要这样：

```cpp
if (locked)
    wait();
```

目前还是Mesa Monitor最为常见。

实现 monitor 需要语言层面的支持。Java有`synchronized`关键字，可以用来实现monitor，但是C++就没有了，不过还是可以用condition variable和RAII，来模拟Mesa monitor。

```cpp
#include <mutex>
#include <condition_variable>

class Monitor{
public:
    Monitor():lk{m, std::defer_lock}{}
    void notify(){cv.notify_one();}
    void broadcast(){cv.notify_all();}
    template<typename F>
    void wait(F pred){cv.wait(lk, pred);};
    std::unique_lock<std::mutex> synchronize()
    {
    return std::unique_lock<std::mutex>{m};
    }
private:
    std::mutex m;
    std::unique_lock<std::mutex> lk;
    std::condition_variable cv;
};
```

来看一个简单的例子，用monitor实现互斥锁。虽然这里例子没什么实际意义，但是足够简单：

```cpp
// To compile: g++ -std=c++14 -lpthread MonitorLock.cpp
        
#include "Monitor.h"
#include <thread>
#include <iostream>

using namespace std;
class MonitorLock{
public:
    void lock()
    {
        // unique_lock 会通过 RAII 自动 unlock
        auto lk = m.synchronize(); 
        m.wait([&](){return !locked;});
        locked = true;
    }
    void unlock()
    {
        auto lk = m.synchronize();
        locked = false;
        m.notify();
    }
private:
    Monitor m;
    bool locked = false;
};
int main()
{
    MonitorLock m;
    thread t1{[&](){
        for (int i = 1; i <= 30; i++){
            m.lock();
            cout << "t1: " << i << endl;
            m.unlock();
        }
    }};
    thread t2{[&](){
        for (int i = 1; i <= 30; i++){
            m.lock();
            cout << "t2: " << i << endl;
            m.unlock();
        }
    }};
    t1.join();
    t2.join();
    return 0;
}
```

另一个例子稍微实用一点，解决生产者消费者问题。

```cpp
// To compile: g++ -std=c++14 -lpthread ProducerConsumer.cpp
        
#include "Monitor.h"
#include <thread>
#include <iostream>
#include <queue>

using namespace std;
template<typename T, int N>
class ProducerConsumer{
public:
    void insert(T& item)
    {
        auto lk = m.synchronize(); 
        // if(!full)
        m.wait([&](){return items.size() < N;});
        items.push(item);
        if(items.size()  == 1){
            m.notify();
        }
        cout << "insert: " << item << endl;
    }
    T remove()
    {
        auto lk = m.synchronize();
        m.wait([&](){return items.size() > 0;}); // if(!empty)
        auto item = items.front();
        items.pop();
        if(items.size() == N-1){
            m.notify();
        }
        cout << "consume: " << item << endl;
        return item;
    }
private:
    Monitor m;
    std::queue<T> items;
};
int main()
{
    ProducerConsumer<int, 10> q;
    thread p{[&](){
        for(int i = 1; i < 30; i++){
            q.insert(i);
        }
    }};
    thread c{[&](){
        for(int i = 1; i < 30; i++){
            auto item = q.remove();
        }
    }};
    p.join();
    c.join();
    return 0;
}
```

上面的例子只适用于单生产者单消费者问题，如果要解决多生产者多消费者问题，一种做法是设置一个 threshold：

```cpp
// insert()
if (items.size() >= comsumerThreshold)
        m.broadcast();
// remove()
if(items.size() <= producerThreshold)
        m.broadcast()
```

或者更细粒度的控制condition variable的使用：

```cpp
// To compile: g++ -std=c++14 -lpthread ProducerConsumer.cpp
        
#include <thread>
#include <iostream>
#include <queue>
#include <mutex>
#include <condition_variable>

using namespace std;
template<typename T, int N>
class ProducerConsumer{
public:
    void insert(T& item)
    {
        std::unique_lock<std::mutex> lk{m};
        insert_cv.wait(lk, [&](){return items.size() < N;}); // if(!full)

        items.push(item);
        // 如果这里是Hoare monitor就会跳转到正在wait的remove函数，
        // 可惜这里是mesa
        remove_cv.notify_one();
        cout << "insert: " << item << endl;
    }
    T remove()
    {
        std::unique_lock<std::mutex> lk{m};
        remove_cv.wait(lk, [&](){return items.size() > 0;}); // if(!empty)

        auto item = items.front();
        items.pop();
        insert_cv.notify_one();
        cout << "consume: " << item << endl;
        return item;
    }
private:
    mutex m;
    condition_variable insert_cv, remove_cv;
    std::queue<T> items;
};
int main()
{
    ProducerConsumer<int, 10> q;
    thread p{[&](){
        for(int i = 1; i < 30; i++){
            q.insert(i);
        }
    }};
    thread c{[&](){
        for(int i = 1; i < 30; i++){
            auto item = q.remove();
        }
    }};
    p.join();
    c.join();
    return 0;
}
```

这里用到了两个条件变量，一个用来提示队列已满，已经用来提示队列已空。

])