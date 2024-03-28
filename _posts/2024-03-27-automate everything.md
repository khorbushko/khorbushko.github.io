---
layout: post
comments: true
title: "Automate everything"
categories: article
tags: [script, automation, excel]
excerpt_separator: <!--more-->
comments_id: 102

author:
- kyryl horbushko
- Kyiv
- 🇺🇦 Ukraine 🇺🇦
---

Automation of each small amount of work that is repeatedly needed in your daily work can significantly speed up everything. 
<!--more-->

As an example, I would like to describe the process of managing anthroponyms for Ukrainian names - quite a simple process, but it can require some ["monkey" actions](https://www.urbandictionary.com/define.php?term=Monkey%20job) each time u need this.

## script

To solve this task, we need to know how to create anthroponyms correctly. Naturally, we, as native speakers of the Ukrainian language, easily do this, but actually [there are](https://udhtu.edu.ua/wp-content/uploads/2017/08/b7ae096b1e5cedc59c9371524703b474.pdf) a lot of rules for this action. To manage these rules we need some tool that can do such action (if there is no tool available we always can create one). Luckily for us, such a tool exists - [shevchenko.js](https://github.com/tooleks/shevchenko-js):

```js
const shevchenko = require('shevchenko');

async function main() {
  const input = {
    gender: 'masculine',
    givenName: 'Тарас',
    patronymicName: 'Григорович',
    familyName: 'Шевченко'
  };

  const output = await shevchenko.inVocative(input);

  console.log(output); // { givenName: "Тарасе", patronymicName: "Григоровичу", familyName: "Шевченку" }
}

main().catch((error) => console.error(error));
```
> sample from [github](https://github.com/tooleks/shevchenko-js)

Exactly what is needed.

The other part - is to manage multiple names at once. Usually, for such kinds of things, we can use [Excel](https://www.microsoft.com/uk-ua/microsoft-365/excel).

To combine Excel with schevchenko we can use another tool [exceljs](https://github.com/exceljs/exceljs).

This is a powerful tool that can do almost everything in Excel for us, and it's very easy to use, for example, to create a workbook, just type:

```js
const workbook = new ExcelJS.Workbook();
```

Now, when all tools are in place - we need just to combine them:

```js
const shevchenko = require('shevchenko');
const Excel = require('exceljs');

async function main() {

  const workbook = new Excel.Workbook();
  
  let filename = "/Users/khb/Documents/names.xlsx"
  await workbook.xlsx.readFile(filename);
  const worksheet = workbook.getWorksheet('names');

  const namesColA = worksheet.getColumn('A').values;
  const namesToProcess = namesColA.flatMap( (element) => {
    return [element.split(" ")];
  })

  const anthroponymValues = namesToProcess.flatMap((components) => {
    return {
      givenName: components[1],
      patronymicName: components[2],
      familyName: components[0]
    }
  });

  var resultsMap = await Promise.all(anthroponymValues.map(async (item) => {
    const gender = await shevchenko.detectGender(item) ?? 'masculine';
    const input = { ...item, gender };
    return input;
  }));

  var inAccusativeResult = await Promise.all(resultsMap.map(async (input) => {
    const output = await shevchenko.inAccusative(input);
    return `${output.familyName} ${output.givenName} ${output.patronymicName}`;
  }));

  const namesColB = worksheet.getColumn('B');
  namesColB.values = inAccusativeResult;

  var inDativeResult = await Promise.all(resultsMap.map(async (input) => {
    const output = await shevchenko.inDative(input);
    return `${output.familyName} ${output.givenName} ${output.patronymicName}`;
  }));

  const namesColC = worksheet.getColumn('C');
  namesColC.values = inDativeResult;

  const namesColD = worksheet.getColumn('D');
  namesColD.values = convertNames(namesToProcess)
  
  const namesColE = worksheet.getColumn('E');
  namesColE.values = convertNames(inAccusativeResult.flatMap( (element) => {
    return [element.split(" ")];
  }))

  const namesColF = worksheet.getColumn('F');
  namesColF.values = convertNames(inDativeResult.flatMap( (element) => {
    return [element.split(" ")];
  }))

  workbook.xlsx.writeFile(filename)
  .then(() => {
    console.log('Job done here! U saved some time for coffee!');
  })
  .catch((error) => {
    console.log(error);
  });
}

function convertNames(names) {
  const namesWithUppercaseSurname = names.flatMap((components) => {
    return `${components[0].toUpperCase()} ${components[1]} ${components[2]}`
  })
  return namesWithUppercaseSurname;
};

main().catch((error) => console.error(error));
```

Input:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-27-automate everything/before.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-27-automate everything/before.png" alt="before" width="500"/>
</a>
</div>
<br>
<br>

Output:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-27-automate everything/after.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-27-automate everything/after.png" alt="after" width="500"/>
</a>
</div>
<br>
<br>

Done!. U can now 
```
    console.log('Job done here! U saved some time for coffee!');
```

## Conclusion

Optimize and automate any aspect of u'r work that is repeated more than twice :]. As a result - u will learn a lot and u will have a lot of additional time for other activities.

## Resources

- [Rools for anthroponyms](https://udhtu.edu.ua/wp-content/uploads/2017/08/b7ae096b1e5cedc59c9371524703b474.pdf)
- [shevchenko.js](https://github.com/tooleks/shevchenko-js)
- [exceljs](https://github.com/exceljs/exceljs)