# Software Requirements Specification
## For Notifications

Version 0.1  
Prepared by Arian Villareal, Nicolas Ré, Pablo Ameri  
Universidad Nacional de Rio Cuarto  
Date: April 2, 2020 

Table of Contents
=================
* [Revision History](#revision-history)
* 1 [Introduction](#1-introduction)
  * 1.1 [Document Purpose](#11-document-purpose)
  * 1.2 [Product Scope](#12-product-scope)
  * 1.3 [Definitions, Acronyms and Abbreviations](#13-definitions-acronyms-and-abbreviations)
  * 1.4 [References](#14-references)
  * 1.5 [Document Overview](#15-document-overview)
* 2 [Product Overview](#2-product-overview)
  * 2.1 [Product Functions](#21-product-functions)
  * 2.2 [User Characteristics](#22-user-Characteristics)
  * 2.3 [Product Restrictions](#23-product-restrictions)
  * 2.4 [Assumptions and dependencies](#24-assumptions-and-dependencies)
* 3 [Specific requirements.](#3-specific-requirements.)
  * 3.1 [External Interfaces](#31-external-interfaces)
  * 3.2 [Functional](#32-functional)
    * 3.2.1 [Class Diagram](#321-class-Diagram)
    * 3.2.2 [Users Stories](#322-user-stories)
  * 3.3 [Performance requirements](#33-serformance-requirements)
  * 3.4 [Design restrictions](#34-design-restrictions)
  * 3.5 [Attributes](#35-sttributes)
 

## Revision History
| Name  | Date     | Reason For Changes  | Version   |
| ----  | -------- | ------------------- | --------- |
|       |14-04-2020|First load           |  0.1      |
|       |          |                     |           |

## 1. Introduction
The document presents the specifications and software requirements for the application dedicated to notifying people mentioned in documents issued by the National University of Rio Cuarto, as well as the view of said documents. 

### 1.1 Document Purpose
The purpose of this software Requirements specification document is to define the design, specifications 
and functionality of the notification system. 
This document will be useful to both developers and the client to reach an understanding between both parties.

### 1.2 Product Scope

The proposed product is a web application dedicated mainly to notifying people who have been mentioned in public documents issued by the UNRC.
It can also be used to see all the documents issued. 
the admins will be the ones who upload the documents and notify the people mentioned in these, and these people must be registered users to receive a notification.Then, by accessing with your username and password you can view the document in question.
other people who enter without registering will do so with the guest category, being able to view the documents issued and loaded in the application
An administrator with the SuperAdmin category will be the one who assigns the administrator function to users.

### 1.3 Definitions, Acronyms and Abbreviations
| Termino     | Descripción                                                        |
| ------------|--------------------------------------------------------------------|
|User         |person who can view documents and receive notifications if included |
|             |in said document, Identifies with your personal data                |
|Admin        |is a user who in turn has the power to upload documents and tag     |
|             |the users involved                                                  |
|Superdmin    |is a user who in turn has the power to upload documents and tag     |
|             |the users involved                                                  |
|Guest        |is the person who enters without registering                        |
|Document     |pdf file with scanned document                                      |
|Notification |is an alert indicating that the user has been named in a document   |

### 1.4 References


### 1.5 Document Overview
The second part will give a general description of the product and the functionalities provided for use. Finally, a structural diagram will be shown and specific requirements will be established.

## 2. Product Overview

### 2.1 Product Functions


#### view documents
any user category you enter can view the documents loaded in the application

#### User Registration
users can register in the application to get the benefit of receiving notifications.
Users will be persons within the scope of the UNRC and their registration will be accepted by an administrator if appropriate.. 

#### login as a registered user
A registered user can enter with their username and password by accessing a list of documents about which they have been notified.


#### upload categories
a user with the category of superAmin, could assign to a registered user, the functionalities corresponding to an admin, asignandole dicha categoria



#### document upload
Admins will be the ones who upload the documents issued by the UNRC for later viewing.


#### modify documents
in the event of an error in the loading of any document, or the need to replace a file, an admin can perform that action


#### delete documents
an admin can delete a loaded document

#### notify users
Administrators will be those who after uploading a document, notify those involved in it.




### 2.2 User Characteristics

The system will have four types of users with different characteristics

#### unregistered users
These will users accessing the system without registering or guests
Unregistered people will not have access to the menu of registered users, they will not be notified nor will they be able to notify other users,
they will not be able to load, modify or delete documents, nor will they be able to load, modify or delete users

#### registered users
are the users who register with their personal data and have an Id
These users will not be able to notify, but will suggest notification to users.
they cannot upload, modify or delete documents, nor can they upload, modify or delete other users

#### Admins
They are registered users with admins functions, they can upload, modify or delete documents, notify, upload, modify or delete users.
admins will not be able to assign the admin category to another user

#### Superadmin
they have all the previous characteristics and also the function of assigning or removing administrators

### 2.3 product restrictions

The update speed in the news, that is, new documents issued by the UNRC, will depend on the speed with which they are loaded into the system, as well as the notification of users, these steps are not automated.
This product can be accessed through the use of web browsers.
it cannot be used without an internet connection, also if this connection is not good it can affect the loading speed in the required requests.
During some maintenance task the system may remain out of service

### 2.4 Assumptions and dependencies

To use it, any device with access to a browser and internet connection will be necessary.

## 3 Specific requirements.

### 3.1 External Interfaces

>------falta dedinir

### 3.2 Functional
#### 3.2.1 Class Diagram
![Diagrama de clases](/Diagram.png)

#### 3.2.2 


### 3.3 Performance requirements

### 3.4 design restrictions

### 3.5 Attributes
