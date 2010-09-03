/*
 * Copyright 2010 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */
package com.google.gwt.requestfactory.client.impl;

import com.google.gwt.json.client.JSONArray;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
import com.google.gwt.junit.client.GWTTestCase;
import com.google.gwt.requestfactory.client.SimpleRequestFactoryInstance;
import com.google.gwt.requestfactory.shared.EntityProxy;
import com.google.gwt.requestfactory.shared.SimpleFooProxy;
import com.google.gwt.requestfactory.shared.WriteOperation;

import java.util.Date;

/**
 * Tests for {@link DeltaValueStoreJsonImpl}.
 */
public class DeltaValueStoreJsonImplTest extends GWTTestCase {

  private static final String SIMPLE_FOO_CLASS_NAME = "com.google.gwt.requestfactory.shared.SimpleFooProxy";

  /*
   * sub-classed it here so that the protected constructor of {@link ProxyImpl}
   * can remain as such.
   */
  private class MyProxyImpl extends ProxyImpl {

    protected MyProxyImpl(ProxyJsoImpl proxy) {
      super(proxy, false);
    }
  }

  ValueStoreJsonImpl valueStore = null;
  RequestFactoryJsonImpl requestFactory = null;

  ProxyJsoImpl jso = null;

  @Override
  public String getModuleName() {
    return "com.google.gwt.requestfactory.RequestFactorySuite";
  }

  @Override
  public void gwtSetUp() {
    valueStore = new ValueStoreJsonImpl();
    requestFactory = (RequestFactoryJsonImpl) SimpleRequestFactoryInstance.factory();

    // add a proxy
    jso = ProxyJsoImpl.fromJson("{}");
    jso.set(SimpleFooProxy.id, 42L);
    jso.set(SimpleFooProxy.version, 1);
    jso.set(SimpleFooProxy.userName, "bovik");
    jso.set(SimpleFooProxy.password, "bovik");
    jso.set(SimpleFooProxy.intId, 4);
    jso.set(SimpleFooProxy.created, new Date());
    jso.set(SimpleFooProxy.boolField, false);
    jso.set(SimpleFooProxy.otherBoolField, true);
    jso.setSchema(SimpleRequestFactoryInstance.schema());
    valueStore.setProxy(jso, requestFactory);
  }

  public void testCreate() {
    EntityProxy created = requestFactory.create(SimpleFooProxy.class);
    assertNotNull(created.getId());
    assertNotNull(created.getVersion());

    DeltaValueStoreJsonImpl deltaValueStore = new DeltaValueStoreJsonImpl(
        valueStore, requestFactory);
    String json = deltaValueStore.toJson();
    JSONObject jsonObject = (JSONObject) JSONParser.parseLenient(json);
    assertFalse(jsonObject.containsKey(WriteOperation.CREATE.name()));
  }

  public void testCreateWithSet() {
    EntityProxy created = requestFactory.create(SimpleFooProxy.class);
    assertNotNull(created.getId());
    assertNotNull(created.getVersion());
    
    DeltaValueStoreJsonImpl deltaValueStore = new DeltaValueStoreJsonImpl(
        valueStore, requestFactory);
    // DVS does not know about the created entity.
    assertFalse(deltaValueStore.isChanged());
    deltaValueStore.set(SimpleFooProxy.userName, created, "harry");
    assertTrue(deltaValueStore.isChanged());
    testAndGetChangeProxy(deltaValueStore.toJson(), WriteOperation.CREATE);
  }

  public void testCreateUpdate() {
    EntityProxy created = requestFactory.create(SimpleFooProxy.class);
    DeltaValueStoreJsonImpl deltaValueStore = new DeltaValueStoreJsonImpl(
        valueStore, requestFactory);
    // DVS does not know about the created entity.
    assertFalse(deltaValueStore.isChanged());
    deltaValueStore.set(SimpleFooProxy.userName, created, "harry");
    assertTrue(deltaValueStore.isChanged());
    JSONObject changeProxy = testAndGetChangeProxy(deltaValueStore.toJson(),
        WriteOperation.CREATE);
    assertEquals(
        "harry",
        changeProxy.get(SimpleFooProxy.userName.getName()).isString().stringValue());
  }

  public void testOperationAfterJson() {
    DeltaValueStoreJsonImpl deltaValueStore = new DeltaValueStoreJsonImpl(
        valueStore, requestFactory);
    deltaValueStore.set(SimpleFooProxy.userName, new MyProxyImpl(jso),
        "newHarry");
    assertTrue(deltaValueStore.isChanged());

    deltaValueStore.toJson();

    try {
      deltaValueStore.set(SimpleFooProxy.userName, new MyProxyImpl(jso),
          "harry");
      fail("Modifying DeltaValueStore after calling toJson should throw a RuntimeException");
    } catch (RuntimeException ex) {
      // expected.
    }

    deltaValueStore.clearUsed();
    deltaValueStore.set(SimpleFooProxy.userName, new MyProxyImpl(jso),
        "harry");
  }

  public void testSeparateIds() {
    ProxyImpl createProxy = (ProxyImpl) requestFactory.create(SimpleFooProxy.class);
    assertTrue(createProxy.isFuture());
    Long futureId = createProxy.getId();

    ProxyImpl mockProxy = new ProxyImpl(ProxyJsoImpl.create(futureId, 1,
        SimpleRequestFactoryInstance.schema()), RequestFactoryJsonImpl.NOT_FUTURE);
    valueStore.setProxy(mockProxy.asJso(), requestFactory); // marked as non-future..
    DeltaValueStoreJsonImpl deltaValueStore = new DeltaValueStoreJsonImpl(
        valueStore, requestFactory);

    deltaValueStore.set(SimpleFooProxy.userName, createProxy, "harry");
    deltaValueStore.set(SimpleFooProxy.userName, mockProxy, "bovik");
    assertTrue(deltaValueStore.isChanged());
    String jsonString = deltaValueStore.toJson();
    JSONObject jsonObject = (JSONObject) JSONParser.parseLenient(jsonString);
    assertFalse(jsonObject.containsKey(WriteOperation.DELETE.name()));
    assertTrue(jsonObject.containsKey(WriteOperation.CREATE.name()));
    assertTrue(jsonObject.containsKey(WriteOperation.UPDATE.name()));

    JSONArray createOperationArray = jsonObject.get(
        WriteOperation.CREATE.name()).isArray();
    assertEquals(1, createOperationArray.size());
    assertEquals("harry", createOperationArray.get(0).isObject().get(
        SIMPLE_FOO_CLASS_NAME).isObject().get(
        SimpleFooProxy.userName.getName()).isString().stringValue());

    JSONArray updateOperationArray = jsonObject.get(
        WriteOperation.UPDATE.name()).isArray();
    assertEquals(1, updateOperationArray.size());
    assertEquals("bovik", updateOperationArray.get(0).isObject().get(
        SIMPLE_FOO_CLASS_NAME).isObject().get(
        SimpleFooProxy.userName.getName()).isString().stringValue());
  }

  public void testUpdate() {
    DeltaValueStoreJsonImpl deltaValueStore = new DeltaValueStoreJsonImpl(
        valueStore, requestFactory);
    deltaValueStore.set(SimpleFooProxy.userName, new MyProxyImpl(jso),
        "harry");
    assertTrue(deltaValueStore.isChanged());
    JSONObject changeProxy = testAndGetChangeProxy(deltaValueStore.toJson(),
        WriteOperation.UPDATE);
    assertEquals(
        "harry",
        changeProxy.get(SimpleFooProxy.userName.getName()).isString().stringValue());
  }

  private JSONObject testAndGetChangeProxy(String jsonString,
      WriteOperation currentWriteOperation) {
    JSONObject jsonObject = (JSONObject) JSONParser.parseLenient(jsonString);
    for (WriteOperation writeOperation : WriteOperation.values()) {
      if (writeOperation != currentWriteOperation) {
        assertFalse(jsonObject.containsKey(writeOperation.name()));
      } else {
        assertTrue(jsonObject.containsKey(writeOperation.name()));
      }
    }

    JSONArray writeOperationArray = jsonObject.get(currentWriteOperation.name()).isArray();
    assertEquals(1, writeOperationArray.size());

    JSONObject proxyWithName = writeOperationArray.get(0).isObject();
    assertEquals(1, proxyWithName.size());
    assertTrue(proxyWithName.containsKey(SIMPLE_FOO_CLASS_NAME));

    JSONObject proxy = proxyWithName.get(SIMPLE_FOO_CLASS_NAME).isObject();
    assertTrue(proxy.containsKey("id"));
    assertTrue(proxy.containsKey("version"));

    return proxy;
  }
}
