// ignore_for_file: must_be_immutable, must_call_super
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:moneywallet/DB/functions/category/category_db.dart';
import 'package:moneywallet/DB/functions/transaction/transaction_db.dart';
import 'package:moneywallet/home/Homescreen/controller/provider/home_screen_provider.dart';
import 'package:moneywallet/home/category/controller/provider/category_provider.dart';
import 'package:moneywallet/home/transaction/controller/provider/transaction_provider.dart';
import 'package:moneywallet/home/transaction/model/transaction_modal.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../Homescreen/view/screen_bottomvavigation.dart';
import '../../category/model/category_typemodel.dart';
import '../model/enum.dart';

class ScreenAddTransaction extends StatelessWidget {
  ScreenAddTransaction({
    Key? key,
    this.index,
    this.type,
    this.modal,
    this.id,
  }) : super(key: key);

  int? index;
  String? id;
  ActionType? type;
  TransactionModel? modal;

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<TransactionProvider>(context, listen: false);
    if (type == ActionType.editscreen) {
      data.dateController.text = DateFormat('yMMMMd').format(modal!.date);
      data.amountController.text = modal!.amount.toString();
      data.selectedCategoryType = modal!.type;
    } else {
      data.selectedCategoryType = CategoryType.income;
      data.dateController.clear();
      data.amountController.clear();
      data.transactionRefresh();
      Provider.of<CategoryProvider>(context, listen: false).refreshUI();
    }
    return Scaffold(
      appBar: AppBar(
        title: data.type == ActionType.addscreen
            ? const Text('ADD TRANSACTION')
            : const Text('EDIT TRANSACTION'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(top: 1.h, left: 4.w, right: 4.w),
          child: Form(
            key: data.formKeyAlert,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 3.h,
                ),
                Text(
                  "Select your category",
                  style: TextStyle(fontSize: 10.sp),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Consumer(
                    builder: (BuildContext context, TransactionProvider value,
                        Widget? child) {
                      return Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(0),
                              horizontalTitleGap: 0,
                              title: const Text("Income"),
                              leading: Radio(
                                value: CategoryType.income,
                                groupValue: value.selectedCategoryType,
                                onChanged: (value) => data.incomeRadioButton(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              horizontalTitleGap: 0,
                              title: const Text("Expense"),
                              leading: Radio(
                                value: CategoryType.expense,
                                groupValue: value.selectedCategoryType,
                                onChanged: (value) => data.expenseRadioButton(),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
                Consumer(
                  builder: (BuildContext context, TransactionProvider values,
                      Widget? child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        DropdownButtonFormField<String>(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) =>
                              data.validator(value, 'select cetegory'),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            icon: Icon(Icons.category),
                          ),
                          hint: const Text('select cetegory'),
                          value: values.dropdownvalueCategory,
                          onChanged: (newValue) {
                            values.dropDownValues(newValue);
                          },
                          items: (values.selectedCategoryType ==
                                      CategoryType.income
                                  ? Provider.of<CategoryProvider>(context,
                                          listen: false)
                                      .incomeCategoryList
                                  : Provider.of<CategoryProvider>(context,
                                          listen: false)
                                      .expenseCategoryList)
                              .map((e) {
                            return DropdownMenuItem(
                                value: e.id,
                                child: Text(e.name),
                                onTap: () {
                                  values.selectedCategoryModel = e;
                                });
                          }).toList(),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await addcategory(context);
                          },
                          label: const Text('New Category'),
                          icon: const Icon(Icons.add),
                        )
                      ],
                    );
                  },
                ),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+(?:-\d+)?$'),
                    )
                  ],
                  validator: (value) => data.validator(value, 'Enter Emount'),
                  controller: data.amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.money),
                    label: Text('Enter Amount'),
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => data.validator(value, 'Select Date'),
                    controller: data.dateController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.calendar_today),
                        labelText: "Select Date"),
                    readOnly: true,
                    onTap: () async => data.pickDate(
                          context,
                        )),
                SizedBox(
                  height: 4.h,
                ),
                ElevatedButton(
                  onPressed: () => transactionSubmit(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('ADD'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> addcategory(BuildContext context) async {
    final data = Provider.of<TransactionProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(10),
          children: [
            Form(
              key: data.formKey,
              child: TextFormField(
                maxLength: 12,
                validator: (value) => data.addCategory(value, context),
                controller:
                    Provider.of<CategoryProvider>(context, listen: false)
                        .categoryNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                  labelText: 'Enter category name',
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Provider.of<HomeScreenProvider>(context, listen: false)
                        .navigatorPop(context);
                    data.categoryClear(context);
                  },
                  child: const Text('CANCEL'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => data.submitCategory(context),
                  child: const Text('ADD'),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void transactionSubmit(context) {
    final data = Provider.of<TransactionProvider>(context, listen: false);
    if (data.formKeyAlert.currentState!.validate()) {
      final amount = data.amountController.text;

      if (amount.isEmpty) {
        return;
      }

      final parsedAmount = double.tryParse(amount);
      if (parsedAmount == null) {
        return;
      }
      data.pickedDate ??= modal?.date;
      if (data.selectedCategoryModel == null) {
        return;
      }

      TransactionModel dbModel = TransactionModel(
        amount: parsedAmount,
        date: data.pickedDate!,
        type: data.selectedCategoryType,
        category: data.selectedCategoryModel!,
        id: type == ActionType.editscreen
            ? modal!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
      );

      if (type == ActionType.editscreen) {
        data.updateTransaction(
          dbModel,
          modal!.id.toString(),
        );
      } else {
        data.addTransaction(dbModel);
      }
      data.textFeildClear();
      data.dropdownvalueCategory = null;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 1),
        elevation: 20,
        content: Text(
          'Transaction successfully added',
        ),
        backgroundColor: Colors.green,
      ));
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ScreenBottomNavbar(),
          ),
          (route) => false);
    }
  }
}
