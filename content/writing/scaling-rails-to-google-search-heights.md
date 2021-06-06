---
title: "Scaling Rails to Google Search Heights"
date: "2021-06-06T22:59:54Z"
tags: [programming, ruby, rails]
---

From time to time I still see people focus heavily on the compute efficiency of tools instead of development speed.
The general worry is always a "what if I paint myself into a corner" scenario and ignores the malleability of software to evolve as necessary to suit a changing problem set.
This is a thought experiment about scaling a technology to Google search levels of traffic and what it would cost.

Google search is widely used and generally regarded as a high-performing page.
This is achieved by computing possible search results and storing them for weighted queries so that the page can simply render those results via HTML.
The focus of the thought experiment is just this: what would it cost to host a page like Google search at that scale using Ruby on Rails.
Ruby is widely regarded to be a _slow_ language and Ruby on Rails is widely regarded to be a _slow_ framework; this must be true because techempower benchmarks show it.

To constrain this thought experiment to avoid getting into the weeds of designing such a highly-available system in its totality I want to focus exclusively on the user interface aspect of Google search.
The architecture of the data storage and querying solution, the bandwidth costs, and the necessary operations teams all stay the same so it should be safe to ignore these costs.
What it costs to generate these pages is the main concern and how those costs change depending on organization size.

The first hurdle is figuring out what scale Google search operates at.
Allegedly, based on my non-exhaustive search, Google processes around 40,000 search requests per second, totalling around 1.2 trillion search requests per year.
I think this is low because Google is the default search engine on a huge number of mobile devices, so lets juice that number a little.
Let's say they serve 120,000 search requests per second as an extended peak, totalling around 3.7 trillion search requests per year.

So what kind of respond times should we expect to get out of this service?
My _astoundingly_ scientific research shows that, for my connection to Google, there is ~100ms TTFB[^1] and ~700ms download time for the page data.
This seems pretty reasonable as a target for this thought experiment, so we will expect requests to finish in 100ms and for the kernel to asynchronously send the data without diving into any kernel engineering specializations for high density servers.
Remember, we're not building CloudFlare, just the search page generation.

There is also the matter of the data size being sent.
The page I tested with came back at just under ~80KB when compressed using gzip, and I'm going to assume that most pages are nearly equivalent to this size.
When calculated out, the network bandwidth required for 120,000 requests per second at ~80KB per response is around 79Gbit/s.
This probably won't come into play since we're not trying to push all this traffic through a single machine, but it's interesting to think about[^2].

Rails has a baseline performance that is shipped by default with puma as an app server.
It ships with configuration for 5 threads per worker to take advantage of concurrent I/O processing and leaves it to the user to configure the number of workers.
This default configuration can service _5W_ requests at any moment, where _W_ is the number of workers chosen.
We will tweak these based on the hardware chosen for the implementation.

Now we can begin to consider what this kind of architecture would cost in the cloud.
If we were to host this kind of service on AWS using EC2 we would want to take advantage of compute optimized instances that have a large amount of memory and a decent set of vCPUs.
To avoid spending too much time optimizing, let's just say we're using a c5.12xlarge instance, which currently has an on-demand cost of US$2.04/hour and supplies 46 vCPUs, 96GB of memory, and 12GBit of bandwidth.

On this VM, if we make another assumption and over-provision workers by 10% of vCPU count, we can run 53 workers and since we serve 1 request in 100ms, that means we can configure 10 threads per worker which totals 530 requests per second being handled by one instance.
Divide the total requests per second by the instance's capabilities and we need a baseline of 267 instances; we will avoid thinking about auto-scaling because it doesn't change the baseline much and we've already juiced the numbers.
Pricing out the compute cost totals US$392,169.60 per month with a 30 day month or US$4,706,035.20 per year.

This seems like a lot.
It's not.
Google made US$181.69 billion in revenue in 2020.
Our yearly compute cost is 0.0024% of Google's revenue and wouldn't even make the balance sheet; it would get stuffed under other miscellaneous expenses because it's so insignificant.
Applying reserved instance pricing decreases the cost by a third for 1-year reservations and makes a small number even smaller.

At Google-scale, with data centre teams, this cost can be reduced much further by running your own hardware.
A not-very-high-end server blade with 32 cores and 64 hyper threads and 128GB of memory only costs around US$6,500.
Doing the same calculations, you'd need around 169 of these not-very-high-end server blades, and buying extra for failure preparations would still decrease your costs by around 75%.
This is possible for a company at Google scale because they have data centre teams.

Technologies tend to scale just fine, what really matters is your data architecture: how you store it and how you retrieve it.
Of course, this thought experiment is purposefully constrained because there is a large amount of complexity with running something like Google search at scale that is external to your compute needs and costs.
What I think it does show is how compute costs tend to become meaningless as companies grow.
Focusing on growing a business instead of squeezing performance out of a technology stack is at least an order of magnitude more important.

[^1]: Time To First Byte.
[^2]: Streaming a 4K video requires bandwidth around 30Mbit/s, which means our juiced Google search numbers are equivalent to streaming around 2,634 4K movies at once.
