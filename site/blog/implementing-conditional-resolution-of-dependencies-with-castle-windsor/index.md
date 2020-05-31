---
title: Implementing conditional resolution of dependencies with Castle.Windsor
description: An easy way to implement feature switches with dependency injection.
date: 2020-05-27
---

Let’s say you are given the task of creating a console program to calculate the given element of the Fibonacci sequence.

Great, that’s easy enough. You can just use your favorite tools: VS Code and dotnet core.

You just open up your terminal, cd into the directory of your projects and type:

``` bash

mkdir DependencyInjectionPlayground
cd DependencyInjectionPlayground
dotnet new console
code .
```

After a little thinking you write the code:

``` csharp

using System;

namespace DependencyInjectionPlayground
{
    class Program
    {
        static void Main(string[] args)
        {
            var n = Convert.ToInt32(args[0]);
            var fibonacciCalculator = new FibonacciCalculator();
            var output = fibonacciCalculator.Calculate(n);
            Console.WriteLine($"The {n}-th element of the fibonacci sequence is {output}");
        }
    }
 
    public class FibonacciCalculator
    {
        //Calculates the n-th element of the fibonacci sequence
        public long Calculate(int n)
        {
            if (n <= 2) return 1;
            return Calculate(n-1) + Calculate(n-2);
        }
    }
}

```

Then click save and go back to the console.

``` bash

dotnet build
dotnet run 5

```

And you get the output:

``` bash

"The 5-th element of the fibonacci sequence is 5"

```

That is until you realize that for large numbers it gets exponentially slower because of the nature of this recursive algorithm.

The damn thing has a time complexity of O(2^n)

As Rocky would say:

![Motivational Rocky!](/images/rocky.png)

So, after you get your inspirational speech you go online and after some googling and Wikipedia reading you come across the article on Memoization.

You update your algorithm to take advantage of your newfound knowledge:

``` csharp

public class MemoizedFibonacciCalculator
{
    private long[] memoized;
    private int current;

    public MemoizedFibonacciCalculator()
    {
        memoized = new long[32];
        memoized[0] = 0;
        memoized[1] = 1;
        memoized[2] = 1;
        current = 2;
    }

    //Calculates the n-th element of the fibonacci sequence
    public long Calculate(int n)
    {
        //if we have calculated the n-th element already, return it
        if (n <= current) return memoized[n];

        //if we haven't then resize the array to hold the new values.
        Array.Resize(ref memoized, n + 1);

        //Calculate all the elements between the currently calculated element
        //and the n-th element and then save them.
        for (int i = current + 1; i <= n; i++)
        {
            memoized[i] = memoized[i - 2] + memoized[i - 1];
        }

        current = n;
        return memoized[current];
    }
}

```

It seems that using our original recursive algorithm sacrifices cpu speed versus the updated algorithm using memoization which sacrifices ram.

We don’t want to limit our users to one or the other as we don’t know where they are going to run this code.

It seems we’ll have to provide them the option to choose the algorithm on runtime.

This is where dependency injection comes into play. Switch to your trusty console and type:

``` bash

dotnet add package Castle.Windsor
dotnet restore
dotnet build

```

After some reading of the Castle Windsor documentation you come across this interface: IHandlerSelector

A “go to definition” returns this:

```

    Summary:

    Implementors of this interface allow to extend the way the container perform component resolution based on some application specific business logic.

```

Perfect.

Let’s write a generic handler selector class that would allow us to apply basic selection criteria to the requested implementations:

``` csharp

public class GenericHandlerSelector : IHandlerSelector
{
    private readonly Func<Type, bool> filter;
    private readonly Func<IHandler, bool> predicate;

    public GenericHandlerSelector(Func<Type, bool> filter, Func<IHandler, bool> predicate)
    {
        this.filter = filter;
        this.predicate = predicate;
    }

    public bool HasOpinionAbout(string key, Type service)
    {
        return filter(service);
    }

    public IHandler SelectHandler(string key, Type service, IHandler[] handlers)
    {
        return handlers.First(predicate);
    }
}

```

This basically allows the bootstrap container code to apply logic to what implementation of an interface the container is going to use.

The code finally looks like this:

``` csharp

using System;
using System.Linq;
using Castle.Windsor;
using Castle.MicroKernel;
using Castle.MicroKernel.Registration;

namespace DependencyInjectionPlayground
{
    class Program
    {
        static void Main(string[] args)
        {
            bool useMemoization = Convert.ToBoolean(args[1]);
            var container = BootstrapContainer(useMemoization);

            var n = Convert.ToInt32(args[0]);
            var fibonacciCalculator = container.Resolve<IFibonacciCalculator>();

            var output = fibonacciCalculator.Calculate(n);
            Console.WriteLine($"The {n}-th element of the fibonacci sequence is {output}");

        }

        static IWindsorContainer BootstrapContainer(bool useMemoization)
        {
            IWindsorContainer container = new WindsorContainer();

            container.Register(Component.For<IFibonacciCalculator>().ImplementedBy<FibonacciCalculator>());
            container.Register(Component.For<IFibonacciCalculator>().ImplementedBy<MemoizedFibonacciCalculator>());

            // filter -> this handler only affects implementations of IFibonacciCalculator
            // handler -> depending on input, choose the implementation we want
            var memoizationHandler = new GenericHandlerSelector(
                (filter) => filter == typeof(IFibonacciCalculator),
                (handler) => useMemoization
                    ? handler.ComponentModel.Implementation == typeof(MemoizedFibonacciCalculator)
                    : handler.ComponentModel.Implementation == typeof(FibonacciCalculator)
                );

            container.Kernel.AddHandlerSelector(memoizationHandler);

            return container;
        }

    }

    public class GenericHandlerSelector : IHandlerSelector
    {
        private readonly Func<Type, bool> filter;
        private readonly Func<IHandler, bool> predicate;

        public GenericHandlerSelector(Func<Type, bool> filter, Func<IHandler, bool> predicate)
        {
            this.filter = filter;
            this.predicate = predicate;
        }

        public bool HasOpinionAbout(string key, Type service)
        {
            return filter(service);
        }

        public IHandler SelectHandler(string key, Type service, IHandler[] handlers)
        {
            return handlers.First(predicate);
        }
    }

    public interface IFibonacciCalculator
    {
        //Calculates the n-th element of the fibonacci sequence
        long Calculate(int n);
    }

    public class FibonacciCalculator : IFibonacciCalculator
    {
        //Calculates the n-th element of the fibonacci sequence
        public long Calculate(int n)
        {
            if (n <= 2) return 1;
            return Calculate(n - 1) + Calculate(n - 2);
        }

    }

    public class MemoizedFibonacciCalculator : IFibonacciCalculator
    {
        private long[] memoized;
        private int current;

        public MemoizedFibonacciCalculator()
        {
            memoized = new long[32];
            memoized[0] = 0;
            memoized[1] = 1;
            memoized[2] = 1;
            current = 2;
        }

        //Calculates the n-th element of the fibonacci sequence
        public long Calculate(int n)
        {
            //if we have calculated the n-th element already, return it
            if (n <= current) return memoized[n];

            Array.Resize(ref memoized, n + 1);

            for (int i = current + 1; i <= n; i++)
            {
                memoized[i] = memoized[i - 2] + memoized[i - 1];
            }
            current = n;
            return memoized[current];
        }
    }
}

```

If we switch back to our trusty console and do a:

``` bash

dotnet build
dotnet run 40 false
dotnet run 40 true

```

The false/true is user input for the use or not of Memoization.

Unless you are running this on a supercomputer, you’ll notice the difference in speed between the two algorithms.

If you want to do a little bit of digging I’d suggest measuring the exact difference in the time it took to run both of these using System.Diagnostics

Happy coding!