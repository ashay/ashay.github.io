---
title: A Rant About Software Bloat
---

# A Rant About Software Bloat #

It seems like as new technology makes faster and beefier machines available to
us, we (as members of the software industry) care less and less about code
bloat.  Bloat is everywhere now -- in software that runs on our phones,
desktops, laptops, even TVs!

Maybe the main reason for the omnipresence of bloat is economics: it's often
cheaper to buy or provision a faster machine to the programmer than it is to pay
the programmer to de-bloat the software stack.  Moreover, it's easy to push the
burden to the end user by having short product lifetimes, so that the product
manufacturer has less to plan and maintain.  And when short-term economics is
prioritized over long-term economics, it is clear that it makes no sense to work
on removing bloat.  I have seen this happen often in the companies that I have
worked at.

Now, I am no economist and it's likely that I am missing something crucial,
because this seems like backward thinking.  Hardware is _expensive_ (ask the CFO
of any chip design company).  It seems so much more economical to get the most
of the same hardware by building software carefully, than it is to design and
manufacture new hardware.  But instead, we get severely underutilized hardware.
As examples of specific cases, the Raspberry Pi 3B under my desk (sometimes)
struggles to run a music library software and high-end dedicated
application-specific integrated circuits (ASICs) in state-of-the-art data
centers remain mostly idle.

All this makes me sad, because it means we are all locked into buying newer,
faster machines forever into the future to address the software slop. Not only
are we, as programmers, resigning to this fate, but we're also _forcing the end
users_ of our tools into buying new equipment for perpetuity.  If our end users
cannot or will not go along with this forced choice, we risk leaving them
behind.  Dan Luu [wrote](https://danluu.com/slow-device) about similar bloat in
code for websites.  Derek Sivers [calls](https://sive.rs/polut) it digital
pollution, and I couldn't agree more.

Perhaps subtly, this post is a call to action: to do more for the end users of
our tools, to care more about reducing waste, and to discourage the culture of
prioritizing short-term economics over long-term economics.
