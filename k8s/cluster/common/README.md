Before getting started, just run:

```
flux install
```

And then apply prod.yml:

```
kubectl apply -f ./prod.yml
```

Common folder is for staging and prod.
And deploy each folder on each cluster.

Then, you also need to deploy dashboards and datasources:

```
kubectl apply -k ./datasources
kubectl apply -k ./dashboards
```