#import "/template.typ": *

#doc-template(
title: "Computing Multi-Head Attention",
date: "July 5, 2026",
parindent: 1.2em,
body: [

Multi-Head Attention is the cornerstone of transformer-based large language models. Yet its computation is hard to picture intuitively, because the matrices get shuffled around in a confusing way. So I wrote this post to work through it.

Abstract letters like $a, b, c$ only add to the mental overhead, so whenever a matrix dimension comes up here, I'll give a unique prime number instead — concrete numbers are easier to follow. Since all dimensional numbers are unique, you don't have to read them as literal sizes; you can just treat each one as a distinct label.

= A Linear Algebra Refresher

When we say an $a times b$ matrix, we mean a matrix with $a$ rows and $b$ columns. You can think of this matrix as made up of $a$ row vectors, or equivalently $b$ column vectors.

Multiplying an $a times b$ matrix $A$ by a $b times c$ matrix $B$ gives an $a times c$ matrix $R$. The element $R_(x y)$, at row $x$ and column $y$, is the inner product of the $x$-th row vector of $A$ and the $y$-th column vector of $B$.

= From Input to Output

Let's start by looking at the input and output. Suppose the input consists of 3 tokens, and each token, after adding positional encoding, is "embedded" into a 5-dimensional vector. So the input here is a $3 times 5$ matrix, which we'll call $X$. Each token is a row vector, written as $X_1, X_2, X_3$.

The output needs to be the same size as the input — also a $3 times 5$ matrix, which we'll call $Y$. Each row of $Y$ is written as $Y_1, Y_2, Y_3$.

= Q, K, V

Let's start with $Q$ and $K$.

Suppose for each token, $Q$ and $K$ are both 7-dimensional vectors; then for 3 tokens, $Q$ and $K$ are $3 times 7$ matrices. To obtain $Q$ and $K$, we define parameter matrices $W_Q$ and $W_K$, both $5 times 7$. Then we do the matrix multiplication:

$ Q &= X W_Q \
  K &= X W_K $

If we transpose $K$ and multiply $Q$ by it, then $Q K^T$ is a $3 times 7$ matrix times a $7 times 3$ matrix, which gives a $3 times 3$ matrix.

We scale this matrix by dividing every entry by $sqrt(7)$, then apply a causal mask, turning the upper triangle into negative infinity. To see what a causal mask does, here's an example: suppose we have a $3 times 3$ matrix:

$ mat(1, 2, 3; 4, 5, 6; 7, 8, 9) $

After applying the causal mask, it becomes:

$ mat(1, -oo, -oo; 4, 5, -oo; 7, 8, 9) $

Then we apply $"softmax"$ to each row; the negative infinities become 0, and the result is a $3 times 3$ matrix whose upper triangle is all zero. We call this $S$:

$ S = "softmax"((Q K^T) / sqrt(7)) $

If you're not familiar with the softmax operation, for now just think of it as a kind of normalization: it maps every number between $-oo$ and $+oo$ into the range 0 to 1, while making sure all the numbers in a row add up to 1.

Finally, suppose for each token, $V$ is an 11-dimensional vector. Then $W_V$ should be a $5 times 11$ matrix. From:

$ V = X W_V $

we get that $V$ is a $3 times 11$ matrix.

Multiplying $S$ and $V$ gives:

$ H = S V $

$H$ is also a $3 times 11$ matrix.

= Multi-Head Attention

Suppose we have 2 heads. That means the $Q, K, V$ above each come in two versions, and so do $W_Q, W_K, W_V$. That is:

$ Q_1 &= X W_(Q 1) \
  K_1 &= X W_(K 1) \
  V_1 &= X W_(V 1) \
  Q_2 &= X W_(Q 2) \
  K_2 &= X W_(K 2) \
  V_2 &= X W_(V 2) $

So we end up with two $H$ matrices too: $H_1, H_2$. Both are $3 times 11$ matrices. Concatenating them gives a $3 times 22$ matrix:

$ "Concat"(H_1, H_2) $

= Output

Through multi-head attention, we've obtained a 22-dimensional vector for each input token. But our output needs to be 5-dimensional, just like the input. So we add a $22 times 5$ parameter matrix $W_O$. Multiplying the $3 times 22$ matrix by the $22 times 5$ matrix gives the $3 times 5$ matrix $Y$:

$ Y = "Concat"(H_1, H_2) W_O $

= Analyzing the Input-Output Relationship

Suppose we treat the whole algorithm above as a black box, and lump all the weights together as $W$. That is:

$ W = (W_(Q 1), W_(K 1), W_(V 1), W_(Q 2), W_(K 2), W_(V 2), W_O) $

Then, analyzing the abstract relationship between input and output row by row, we can write:

$ Y_1 &= f_1(X_1; W) \
  Y_2 &= f_2(X_1, X_2; W) \
  Y_3 &= f_3(X_1, X_2, X_3; W) $

Here the functions $f_1, f_2, f_3$ are fixed once the algorithm and hyperparameters are chosen; $W$ holds the trainable weights. Notice that the $N$-th row of the output is determined entirely by the first $N$ rows of the input.

= KV Cache

Suppose that after computing $Y$, we append a 4th row $X_4$ to the input $X$, while $X_1, X_2, X_3$ stay unchanged. By the analysis above, $Y_1, Y_2, Y_3$ also stay unchanged, and we only need to compute $Y_4 = f_4(X_1, X_2, X_3, X_4; W)$.

Notice that in all the intermediate results above, every matrix with 3 rows becomes a matrix with 4 rows, while the first three rows stay exactly the same. So if we cache those first three rows, we only need to compute the fourth row — which saves a lot of computation. Going further, notice that the 4th row of matrix $H$ has nothing to do with the first three rows of $Q$, so the contents of $Q$ can be discarded right after use. This is precisely how the KV Cache saves computation.

= Closing

To wrap up, here's the architecture diagram from the #link("https://cdn.openai.com/research-covers/language-unsupervised/language_understanding_paper.pdf", "original GPT paper"):

#image("./gpt.jpg", width: 35%)

As you can see, the only genuinely intricate part is the multi-head attention discussed in this post. The parts not covered here — residual connections, layer norm, and the FFN — are all fairly straightforward, so I won't go into them.

])
