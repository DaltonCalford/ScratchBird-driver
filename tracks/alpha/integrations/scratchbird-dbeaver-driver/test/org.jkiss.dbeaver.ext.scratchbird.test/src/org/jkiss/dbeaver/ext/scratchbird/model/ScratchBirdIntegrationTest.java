/*
 * DBeaver - Universal Database Manager
 * Copyright (C) 2010-2026 DBeaver Corp and others
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.jkiss.dbeaver.ext.scratchbird.model;

import org.eclipse.core.runtime.Platform;
import org.junit.Assert;
import org.junit.Test;
import org.osgi.framework.Bundle;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

public class ScratchBirdIntegrationTest {

    @Test
    public void pluginXmlDeclaresRecursiveMetadataTreeAndDdlFolders() throws IOException {
        String pluginXml = readHostPluginXml();

        Assert.assertTrue(pluginXml.contains("property=\"schemaTree\""));
        Assert.assertTrue(pluginXml.contains("property=\"childSchemas\""));
        Assert.assertTrue(pluginXml.contains("recursive=\"..\""));

        Assert.assertTrue(pluginXml.contains("type=\"org.jkiss.dbeaver.ext.generic.model.GenericTable\""));
        Assert.assertTrue(pluginXml.contains("type=\"org.jkiss.dbeaver.ext.generic.model.GenericView\""));

        Assert.assertTrue(pluginXml.contains("id=\"scratchbird_jdbc\""));
        Assert.assertTrue(pluginXml.contains("class=\"com.scratchbird.jdbc.SBDriver\""));
    }

    @Test
    public void schemaTreeBuilderBuildsHierarchyAndPreservesParentScopedUniqueness() {
        List<ScratchBirdSchemaTreeBuilder.Node> roots = ScratchBirdSchemaTreeBuilder.build(Arrays.asList(
            "sys",
            "users.alice.dev",
            "users.alice.prod",
            "users.bob.dev",
            "users.bob.dev",
            "analytics.dev",
            "analytics.prod"));

        Assert.assertEquals(3, roots.size());

        ScratchBirdSchemaTreeBuilder.Node users = findNodeByName(roots, "users");
        Assert.assertNotNull(users);

        ScratchBirdSchemaTreeBuilder.Node alice = findNodeByName(users.getChildren(), "alice");
        ScratchBirdSchemaTreeBuilder.Node bob = findNodeByName(users.getChildren(), "bob");
        Assert.assertNotNull(alice);
        Assert.assertNotNull(bob);

        Assert.assertNotNull(findNodeByName(alice.getChildren(), "dev"));
        Assert.assertNotNull(findNodeByName(alice.getChildren(), "prod"));
        Assert.assertNotNull(findNodeByName(bob.getChildren(), "dev"));
        Assert.assertEquals(1, bob.getChildren().size());

        ScratchBirdSchemaTreeBuilder.Node sys = findNodeByName(roots, "sys");
        Assert.assertNotNull(sys);
        Assert.assertTrue(sys.isTerminal());
    }

    private static String readHostPluginXml() throws IOException {
        Bundle bundle = Platform.getBundle("org.jkiss.dbeaver.ext.scratchbird");
        if (bundle != null) {
            URL pluginXml = bundle.getEntry("plugin.xml");
            if (pluginXml != null) {
                try (InputStream stream = pluginXml.openStream()) {
                    byte[] bytes = stream.readAllBytes();
                    return new String(bytes, StandardCharsets.UTF_8);
                }
            }
        }

        Path fallbackPath = Path.of(System.getProperty("user.dir"))
            .resolve("../../plugins/org.jkiss.dbeaver.ext.scratchbird/plugin.xml")
            .normalize();
        Assert.assertTrue("ScratchBird plugin.xml not found: " + fallbackPath, Files.exists(fallbackPath));
        return Files.readString(fallbackPath, StandardCharsets.UTF_8);
    }

    private static ScratchBirdSchemaTreeBuilder.Node findNodeByName(
        Collection<ScratchBirdSchemaTreeBuilder.Node> nodes,
        String name
    ) {
        for (ScratchBirdSchemaTreeBuilder.Node node : nodes) {
            if (name.equals(node.getName())) {
                return node;
            }
        }
        return null;
    }
}
