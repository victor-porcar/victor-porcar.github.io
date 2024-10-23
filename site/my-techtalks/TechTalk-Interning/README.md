 # Tech Talk: Interning

Interning is a way to optimise memory usage in specific scenarios by reusing the same instance in the context of immutable objects.


*   [Introduction](#InterningLibrary-Introduction)
*   [Example](#InterningLibrary-Example)
*   [Interning process](#InterningLibrary-Interningprocess)
*   [Interner](#InterningLibrary-Interner)

## Introduction

Let’s see how it works by using a real example:

Let’s suppose there is a table “CAR” in our database model that holds information about cars we have to rent, the car table has the following structure:

![Interning](./interning.png)


where for example column “**brand**” is a string that takes one of the following values:

*   FORD
    
*   OPEL
    
*   BMW
    
*   VOLKSWAGEN
    

Now, let’s suppose we have to build a java service that loads all cars from database to a list in memory

The typical approach would be something like this:

```java
private final static String RETRIEVE_CAR= "select * from car";

public void readCarsFromDatabase() {
            
              List<Car> carList;
  
              carList = jdbcTemplate.query(RETRIEVE_CAR, rs -> {
              
                // this iterates for each row in table CAR
              
                Car car = new Car();
                
                String plate = rs.getString("PLATE");
                content.setPlate(plate);
                
                
                // brand
                String brand = rs.getString("BRAND");
                content.setBrand(brand);
                ...
        });
}
```

As it is known, the method **rs.getString(…)** returns a new String instance with the value of corresponding colum in the row.

As consequence, line 18 creates for each iteration a new String with four possible values: FORD, OPEN,BMW,VOLKSWAGEN

Let’s suppose there are 23000 FORD cars, 40000 OPEL cars, 10000 BMW cars and 80000 VOLKSWAGEN car

This means that in memory we have:

*   23000 instaces of a String having the value “FORD”
    
*   40000 instances of a String having the value “OPEL”
    
*   10000 instances of a String having the value “BMW”
    
*   80000 instances of a String having the value “VOLKSWAGEN”
    

Taken into consideration that a String is an inmutable in Java, this is totally **a waste of memory,** because all Cars being FORD could just point to just one String with the value “FORD” and so on…

Same happens with classes that are directly inmutable:

*   Long, Integer, Boolean, etc…
    

or model classes that are inmutable by definition of our business logic, this includes our own beans or collections.

Interning process
-----------------

Interning is a way to reuse the same instance for cases like the ones described above.

It could be achieve by using a **interner** component

Let’s have a look how it would work using the previous example

```java
Interner interner = Interner.instance();

private final static String RETRIEVE_CAR = "select * from CAR";

public void readCarsFromDatabase() {
            
              List<Car> carList;
  
              carList = jdbcTemplate.query(RETRIEVE_CAR, rs -> {
              
                // this iterates for each row in table CAR
              
                Car car = new Car();
                
                String plate = rs.getString("PLATE");
                content.setPlate(plate);
                
                
                // brand
                String brand = rs.getString("BRAND");
                String internedBrand = interner.internString(brand);
                content.setBrand(internedBrand);
                ...
        });
}
```

let’s focus on line 21

```java
String internedBrand = interner.internString(brand);
```

method **internString** will return an instance of a String with the same value of the given one, It could be the own given instance or not, but this does not matter, because it is assured the value is the same!

but wait a minute!!, you said that line 20 created a new instance for each iteration, what happens with all these instances? the answer is that because those instance are not longer pointed by any object, they are rapidly removed by garbage collector.

Interner
--------

Interner is a component that uses basically a Map to maintain one and only one instance of a given object, that instance in the map can be thought as the “representative” of all equal instances.

So, it keeps in memory the very first instance “interned”.

```java
public class Interner {
    private Map<String,String> stringMap = Collections.synchronizedMap(new HashMap<String,String>());
     ...
    
    public String internString(String value) {
        if (value==null) {
           return null;
        }
        
        String internedValue = stringMap.get(value);
        if (internedValue==null) {
          internedValue = value;
          stringMap.put(internedValue,internedValue);
        }
        return internedValue;
        
    }
  
    
    public String internInteger(Integer value) {
     ... same code but for integers
    }
    
    ...
}
```

