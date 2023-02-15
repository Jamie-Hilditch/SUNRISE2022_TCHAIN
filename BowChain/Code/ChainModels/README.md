# Chain Models

## Catenary Model

A chain hanging under a buoyancy force forms a catenary. It satisfies

$$ \frac{\mathrm{d}z}{\mathrm{d}x} = ks $$

where $s$ is the arclength along the curve measured from the point where it is horizontal and $k^{-1}$ is the length scale of the catenary. However, the horizontal point of the catenary is not a very conveninent place to measure the arclength from as it's not on the chain. Therefore, we will redefine the arclength, $s$, such that $s = 0$ at the first pressure sensor. This pressure sensor will have coordinates $(x_0,z_0)$ and we define $x = 0$ at the top of the chain where $s = -s_0 < 0$. When using the first pressure sensor we know $z_0$ exactly if we require that the catenary passes through that point. Alternatively, if we do not wish to single out the first pressure sensor as special, we could leave $z_0$ as an additional parameter to be found through the minimisation. However, the minimisation is already very expensive. Finally, we should note that there is nothing special about the choice of the first pressure sensor, the exact same reasoning will work for any of the pressure sensors on the chain.

 ![](./Catenary_schematic.jpg "Catenary Schematic")

The chain now satisfies 

$$ \frac{\mathrm{d}z}{\mathrm{d}x} = ks - \tan\theta $$

with $x = x_0$, $z = z_0$ at $s = 0$ and $x = 0$ at $s = -s_0$.

$\theta \in (0,\frac{\pi}{2})$ is the angle of the catenary down from the horizontal at the first pressure sensor.

We need to solve for $k$ and $\theta$.

If the chain is less dense than the water then it hangs as in the schematic and $k$ is negative. However, if the chain is more dense than the water the catenary bends the other way and $k$ is positive. $k = 0$ corresponds to a straight chain which is a very good approximation when a heavy bottom weight is used. This case needs to be treated carefully as the equations below tend to have removable singularities at this point.

### Catenary Solution

The arclength satisfies

$$ \frac{\mathrm{d}s}{\mathrm{d}x} = \sqrt{1 + \left(\frac{\mathrm{d}z}{\mathrm{d}x}\right)^2} = \sqrt{1 + \left(ks - \tan\theta\right)^2} \tag{$\dagger$}$$

and hence 

$$ \frac{\mathrm{d}z}{\mathrm{d}s} = \frac{ks - \tan\theta}{\sqrt{1 + (ks - \tan\theta)^2}} $$ 

Solving for $z$ gives 

$$ z - z_0 = k^{-1}\left[\sqrt{1 + (ks - \tan\theta)^2} - \sqrt{1 + \tan^2\theta} \tag{$\ddagger$}\right] = k^{-1}\left[\sqrt{\sec^2\theta - 2ks\tan\theta + k^2s^2} - \sec\theta\right] $$

Note that in the limit $k \to 0$ we have 

$$ z - z0 = \frac{\sec\theta}{k}\left[1 - \frac{ks\tan\theta}{\sec^2\theta} + O\left(k^2\right) - 1\right] = -\sin\theta s + O(k)$$

as we would expect for a straight chain hanging down with angle $\theta$.

### Determining Parameters 

$z_0$ is known so introduce $z' = z - z_0$ and now ($\dagger$) gives

$$ kz' = \sqrt{\sec^2\theta - 2ks\tan\theta + k^2s^2} - \sec\theta $$

Given two points, $(s_1,z'_1)$ and $(s_2,z'_2)$, on the catenary we can solve for $k$ and $\alpha$.

$$ (kz'_i + \sec\theta)^2 = k^2s_i^2 -2\tan\theta k s_i + \sec^2\theta $$

$$ k^2{z'_i}^2 + 2kz_i \sec\theta = k^2s_i^2 - 2ks_i \tan\theta $$

$$s_i k^{-1}\tan\theta + z'_i k^{-1}\sec\theta = \frac{1}{2}\left(s_i^2 - {z'_i}^2\right) $$

$$ \mathbf{x} = \frac{1}{k}\begin{pmatrix} 
   \tan\theta \\
   \sec\theta \\
   \end{pmatrix} =  \mathbf{A}^{-1}\mathbf{y} $$

where 

$$ \mathbf{A} = \begin{pmatrix}
    s_1 & z'_1 \\
    s_2 & z'_2 \\
    \end{pmatrix}, \quad 
    \mathbf{y} = \frac{1}{2}\begin{pmatrix}s_1^2 - {z'_1}^2 \\
        s_2^2 - {z'_2}^2 \end{pmatrix} $$

Then, $k \neq 0$ and $\theta$ are found by

$$ \sin\theta = \frac{x_1}{x_2} \implies \theta = \sin^{-1} \frac{x_1}{x_2} $$

$$ k = \frac{\tan\theta}{x_1} $$

However, this breaks if the chain is straight, i.e. $k = 0$, because $\mathbf{A}$ is singular. This is a  necessary and sufficient condition and hence we can just catch this case then set $k = 0$ and $\theta = \sin^{-1}\left(-\frac{s_1}{z_1}\right)$.


### Solving for $x$ ###

Inverting ($\dagger$) then integrating gives

$$ x - x_0 = k^{-1}\left[\mathrm{arcsinh}\left(ks - \tan\theta\right) + \mathrm{arcsinh}\left(\tan\theta\right)\right] $$

Note that in the limit $k \to 0$ this reduces to 

$$ x - x_0 = s\cos\theta + O(k) $$

as we expect for a straight chain.

We specify that $x = 0$ when $s = -s_0 < 0$. Therefore, for $k \neq 0$,

$$ x_0 = k^{-1}\left(\mathrm{arcsinh}\left(\tan\theta + ks_0\right) - \mathrm{arcsinh}\left(\tan\theta\right)\right) $$

and thus

$$ x = k^{-1}\left(\mathrm{arcsinh}\left(\tan\theta + ks_0\right) - \mathrm{arcsinh}\left(\tan\theta - ks\right)\right) $$

and for $k = 0$

$$ x = (s + s_0)\cos\theta $$

### Numerical Solution

Given some points, $(s_i, z'_i)$, $ i = 1$ , ..., $ N $ with $N > 2$, on the chain, not including the first pressure sensor, we need to find the values of $k$ and $\theta$ that minimise 

$$ r = \frac{1}{N}\sum_{i = 1}^N (z'(s_i) - z'_i)^2 $$

where 

$$ z'(s_i) = \begin{cases} k^{-1}\left(\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2} - \sec\theta\right) & k \neq 0 \\ 
-\sin\theta s & k = 0 \end{cases} $$
This is a non-linear optimisation which we will solve using the _'trust-region'_ algorithm from the MATLAB optimization toolbox. This requires the gradient and Hessian of $r$. 

$$ \frac{\partial r}{\partial k} = \frac{1}{N}\sum_{i = 1}^N 2(z'(s_i) - z'_i)\left\{k^{-2}\left[\frac{ks_i\tan\theta - \sec^2\theta}{\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2}} + \sec\theta\right]\right\} $$

$$ \frac{\partial r}{\partial \theta} = \frac{1}{N}\sum_{i = 1}^N 2(z'(s_i) - z'_i)\left\{k^{-1}\left[\frac{\sec^2\theta\left(\tan\theta - ks_i\right)}{\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2}} - \sec\theta\tan\theta\right]\right\} $$

$$ \frac{\partial^2 r}{\partial k^2} = \frac{1}{N}\sum_{i = 1}^N 2\left\{k^{-2}\left[\frac{ks_i\tan\theta - \sec^2\theta}{\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2}} + \sec\theta\right]\right\}^2 + \\
 2(z'(s_i) - z'_i)\left\{k^{-3}\left[\frac{k^2s_i^2}{\sqrt{k^2s_i^2-2ks_i\tan\theta + \sec^2\theta}^3} - 2\left(\frac{ks_i\tan\theta - \sec^2\theta}{\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2}} + \sec\theta\right)\right]\right\} $$

$$ \frac{\partial^2 r}{\partial k\partial \theta} = \frac{1}{N}\sum_{i = 1}^N 2k^{-3}\left[\frac{ks_i\tan\theta - \sec^2\theta}{\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2}} + \sec\theta\right]\left[\frac{\sec^2\theta\left(\tan\theta - ks_i\right)}{\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2}} - \sec\theta\tan\theta\right] + \\ 
2(z'(s_i) - z'_i)\left\{k^{-2}\left[\frac{\sec^2\theta\left((ks - \tan\theta)^3 - \tan\theta\right)}{\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2}^3} + \sec\theta\tan\theta\right]\right\} $$

$$ \frac{\partial^2 r}{\partial \theta^2} = \frac{1}{N}\sum_{i = 1}^N 2 \left\{k^{-1}\left[\frac{\sec^2\theta\left(\tan\theta - ks_i\right)}{\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2}} - \sec\theta\tan\theta\right]\right\}^2 + \\ 
 2(z'(s_i) - z'_i)k^{-1}\left\{\frac{-\sec^4\theta(\tan\theta - ks_i)^2}{\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2}^3} + \frac{\sec^2\theta(\sec^2\theta + 2\tan\theta(\tan\theta - ks_i))}{\sqrt{\sec^2\theta - 2ks_i\tan\theta + k^2s_i^2}} - \sec\theta\tan^2\theta - \sec^3\theta\right\} $$

We need to deal with the case $k = 0$. The get the exact gradients by finding the limit as $k \to 0$. Then we find a very good approximation to the Hessian by setting $k$ to be some very small number.

$$ \left.\frac{\partial r}{\partial k}\right|_{k=0} = \frac{1}{N}\sum_{i = 1}^N 2(z'(s_i) - z'_i)\frac{1}{2}\cos^3\theta s^2 $$

$$ \left.\frac{\partial r}{\partial \theta}\right|_{k=0}\frac{1}{N}\sum_{i = 1}^N 2(z'(s_i) - z'_i)\tan\theta(\sin\theta - 1)s_i $$

Finally, we also require an initial guess which we get by computing $k$ and $\theta$ for every pair of points and then taking the median values.

